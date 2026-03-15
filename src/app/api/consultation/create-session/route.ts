import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'crypto';
import { getStripe } from '@/lib/stripe';
import { createClient } from '@/lib/supabase/server';
import { CONSULTATION_PACKAGES } from '@/types/consultation';
import type { PackageType } from '@/types/consultation';

export const maxDuration = 10;

type CheckoutPlatform = 'web' | 'ios_native';
interface CreateSessionRequestBody {
  packageType: PackageType;
  email: string;
  orderId: string;
  platform?: CheckoutPlatform;
}

function sanitizeOrderId(candidate: string): string {
  const trimmed = candidate.trim();
  const isUUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(trimmed);
  return isUUID ? trimmed : randomUUID();
}

async function ensureOrderExists(orderId: string, email: string, packageType: PackageType, priceCents: number) {
  const supabase = await createClient();
  const { data: existingOrder, error: selectError } = await supabase
    .from('orders')
    .select('id')
    .eq('id', orderId)
    .maybeSingle();

  if (selectError) {
    throw new Error(`Order lookup failed: ${selectError.message}`);
  }

  if (existingOrder) {
    return;
  }

  const now = new Date().toISOString();
  const { error: insertError } = await supabase
    .from('orders')
    .insert({
      id: orderId,
      email,
      package_type: packageType,
      price_cents: priceCents,
      payment_status: 'pending',
      report_status: 'pending',
      retry_count: 0,
      quiz_responses: {},
      selected_colors: [],
      photo_urls: [],
      surface_type: 'Walls',
      window_direction: 'unknown',
      address: '',
      created_at: now,
      updated_at: now,
    });

  if (insertError) {
    throw new Error(`Order insert failed: ${insertError.message}`);
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { packageType, email, orderId } = body as CreateSessionRequestBody;
    const platform: CheckoutPlatform = body.platform === 'ios_native' ? 'ios_native' : 'web';

    const pkg = CONSULTATION_PACKAGES[packageType];
    if (!pkg) {
      return NextResponse.json({ error: 'Invalid package type' }, { status: 400 });
    }

    if (!email || !orderId) {
      return NextResponse.json({ error: 'Email and order ID are required' }, { status: 400 });
    }

    const normalizedOrderId = sanitizeOrderId(orderId);
    const lineItemName = pkg.name;
    const lineItemDescription = pkg.description;
    const lineItemPriceCents = pkg.priceCents;

    await ensureOrderExists(normalizedOrderId, email, packageType, lineItemPriceCents);

    const stripe = getStripe();

    if (platform === 'ios_native') {
      const publishableKey =
        process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY ||
        process.env.STRIPE_PUBLISHABLE_KEY;
      if (!publishableKey) {
        return NextResponse.json({ error: 'Stripe publishable key is not configured' }, { status: 500 });
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: lineItemPriceCents,
        currency: 'usd',
        automatic_payment_methods: { enabled: true },
          receipt_email: email,
          metadata: {
            orderId: normalizedOrderId,
            packageType,
            platform: 'ios_native',
          },
      });

      if (!paymentIntent.client_secret) {
        return NextResponse.json({ error: 'Failed to create payment intent' }, { status: 500 });
      }

      return NextResponse.json({
        orderId: normalizedOrderId,
        paymentIntentClientSecret: paymentIntent.client_secret,
        publishableKey,
        merchantCountryCode: (process.env.STRIPE_MERCHANT_COUNTRY || 'US').toUpperCase(),
        message: `Secure checkout is ready for ${pkg.name}.`,
        createdAt: new Date().toISOString(),
      });
    }

    const session = await stripe.checkout.sessions.create({
      ui_mode: 'embedded',
      customer_email: email,
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: lineItemName,
              description: lineItemDescription,
            },
            unit_amount: lineItemPriceCents,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      return_url: `${request.nextUrl.origin}/consultation/status/${normalizedOrderId}?session_id={CHECKOUT_SESSION_ID}`,
      metadata: {
        orderId: normalizedOrderId,
        packageType,
      },
    });

    return NextResponse.json({ clientSecret: session.client_secret });
  } catch (error) {
    console.error('Create session error:', error);
    return NextResponse.json(
      { error: 'Failed to create payment session' },
      { status: 500 }
    );
  }
}
