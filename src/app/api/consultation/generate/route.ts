import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';
import { generateReport } from '@/lib/claude';
import { geocodeAddress } from '@/lib/geocoding';
import { calculateSunAnalysis, getLightingDescription } from '@/lib/sun-analysis';
import { calculateColorShifts } from '@/lib/color-shift';
import { generatePaintVisualization } from '@/lib/gemini';
import { buildPaintPrompt } from '@/lib/prompt';
import { sendReportEmail } from '@/lib/email';
import { CONSULTATION_PACKAGES } from '@/types/consultation';
import type { PackageType } from '@/types/consultation';
import { randomUUID } from 'crypto';

export const maxDuration = 60;

export async function POST(request: NextRequest) {
  const { orderId } = await request.json();

  if (!orderId) {
    return NextResponse.json({ error: 'Order ID is required' }, { status: 400 });
  }

  const supabase = await createClient();

  // Fetch the order
  const { data: order, error: orderError } = await supabase
    .from('orders')
    .select('*')
    .eq('id', orderId)
    .single();

  if (orderError || !order) {
    return NextResponse.json({ error: 'Order not found' }, { status: 404 });
  }

  if (order.report_status === 'complete') {
    return NextResponse.json({ status: 'already_complete' });
  }

  try {
    // 1. Geocode address (use stored lat/lng if available)
    let latitude = order.latitude;
    let longitude = order.longitude;

    if (!latitude || !longitude) {
      try {
        const geo = await geocodeAddress(order.address);
        latitude = geo.latitude;
        longitude = geo.longitude;

        await supabase
          .from('orders')
          .update({ latitude, longitude })
          .eq('id', orderId);
      } catch {
        // Fallback: use a default location (Chicago) for sun data
        latitude = 41.8781;
        longitude = -87.6298;
      }
    }

    // 2. Calculate sun data
    const sunAnalysis = calculateSunAnalysis(latitude, longitude);
    const lightingDescription = getLightingDescription(order.window_direction || 'unknown');

    // 3. Generate color recommendations via Claude
    const quizResponses = order.quiz_responses || {};
    const reportInput = {
      roomType: quizResponses.roomType || 'Living Room',
      mood: quizResponses.mood || 'clean_modern',
      selectedColors: order.selected_colors || [],
      surfaceType: order.surface_type || 'Walls',
      windowDirection: order.window_direction || 'unknown',
      sunData: {
        sunrise: sunAnalysis.sunrise,
        sunset: sunAnalysis.sunset,
        dayLengthHours: sunAnalysis.dayLengthHours,
        lightingDescription,
      },
      packageType: order.package_type,
    };

    const generatedReport = await generateReport(reportInput);

    // 4. Calculate time-of-day color shifts for each recommendation
    const recommendations = generatedReport.recommendations.map((rec) => {
      const shifts = calculateColorShifts(rec.hex, order.window_direction || 'unknown');
      return {
        ...rec,
        morningHex: shifts.morningHex,
        afternoonHex: shifts.afternoonHex,
        eveningHex: shifts.eveningHex,
      };
    });

    // 5. Generate visualizations via Gemini (if photos available)
    if (order.photo_urls?.length > 0) {
      const firstPhotoUrl = order.photo_urls[0];
      try {
        // Fetch the photo
        const photoResponse = await fetch(firstPhotoUrl);
        const photoBuffer = await photoResponse.arrayBuffer();
        const photoBase64 = Buffer.from(photoBuffer).toString('base64');
        const mimeType = photoResponse.headers.get('content-type') || 'image/jpeg';

        // Generate visualization for each recommended color (limit to 3 for timeout safety)
        const vizLimit = Math.min(recommendations.length, 3);
        for (let i = 0; i < vizLimit; i++) {
          try {
            const rec = recommendations[i];
            const prompt = buildPaintPrompt({
              surface: order.surface_type || 'Walls',
              colorName: rec.colorName,
              colorNumber: rec.colorNumber,
              colorHex: rec.hex,
            });

            const result = await generatePaintVisualization(prompt, photoBase64, mimeType);

            // Upload visualization to Supabase Storage
            const vizFileName = `reports/${orderId}/viz-${i}-${rec.colorNumber.replace(/[^a-zA-Z0-9]/g, '')}.jpg`;
            const vizBuffer = Buffer.from(result.data, 'base64');

            const { data: uploadData } = await supabase.storage
              .from('consultation-assets')
              .upload(vizFileName, vizBuffer, {
                contentType: result.mimeType,
                upsert: true,
              });

            if (uploadData) {
              const { data: urlData } = supabase.storage
                .from('consultation-assets')
                .getPublicUrl(vizFileName);
              recommendations[i].visualizationUrl = urlData.publicUrl;
              recommendations[i].originalUrl = firstPhotoUrl;
            }
          } catch (vizError) {
            console.error(`Visualization ${i} failed:`, vizError);
            // Continue without this visualization
          }
        }
      } catch (photoError) {
        console.error('Photo processing failed:', photoError);
        // Continue without visualizations
      }
    }

    // 6. Create the report record
    const accessToken = randomUUID();
    const reportId = randomUUID();

    const sunData = {
      sunrise: sunAnalysis.sunrise,
      sunset: sunAnalysis.sunset,
      solarNoon: sunAnalysis.solarNoon,
      goldenHour: sunAnalysis.goldenHour,
      sunPath: sunAnalysis.sunPath,
      dayLengthHours: sunAnalysis.dayLengthHours,
      lightingAnalysis: lightingDescription,
    };

    const { error: reportError } = await supabase
      .from('reports')
      .insert({
        id: reportId,
        order_id: orderId,
        access_token: accessToken,
        report_data: {
          executiveSummary: generatedReport.executiveSummary,
          applicationTips: generatedReport.applicationTips,
          surfacePrep: generatedReport.surfacePrep,
        },
        sun_data: sunData,
        color_recommendations: recommendations,
        created_at: new Date().toISOString(),
      });

    if (reportError) {
      throw new Error(`Failed to save report: ${reportError.message}`);
    }

    // 7. Update order status
    await supabase
      .from('orders')
      .update({
        report_status: 'complete',
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    // 8. Send email notification
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || request.nextUrl.origin;
    const reportUrl = `${baseUrl}/consultation/report/${reportId}?token=${accessToken}`;
    const pkg = CONSULTATION_PACKAGES[order.package_type as PackageType];

    try {
      await sendReportEmail({
        to: order.email,
        reportUrl,
        packageName: pkg?.name || 'Color Report',
      });
    } catch (emailError) {
      console.error('Email sending failed:', emailError);
      // Report is still accessible via the status page
    }

    return NextResponse.json({
      status: 'complete',
      reportId,
      reportUrl,
    });
  } catch (error) {
    console.error('Report generation failed:', error);

    // Update order with failure status
    await supabase
      .from('orders')
      .update({
        report_status: 'failed',
        retry_count: (order.retry_count || 0) + 1,
        updated_at: new Date().toISOString(),
      })
      .eq('id', orderId);

    return NextResponse.json(
      { error: 'Report generation failed' },
      { status: 500 }
    );
  }
}
