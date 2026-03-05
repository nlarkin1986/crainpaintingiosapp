import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

export const maxDuration = 10;

export async function GET(request: NextRequest) {
  // Verify cron secret
  const authHeader = request.headers.get('authorization');
  if (authHeader !== `Bearer ${process.env.CRON_SECRET}`) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const supabase = await createClient();

  // Find failed orders with retry_count < 3
  const { data: failedOrders, error } = await supabase
    .from('orders')
    .select('id')
    .eq('report_status', 'failed')
    .eq('payment_status', 'paid')
    .lt('retry_count', 3);

  if (error || !failedOrders?.length) {
    return NextResponse.json({ retried: 0 });
  }

  const baseUrl = process.env.NEXT_PUBLIC_APP_URL || request.nextUrl.origin;
  let retried = 0;

  for (const order of failedOrders) {
    try {
      await fetch(`${baseUrl}/api/consultation/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ orderId: order.id }),
      });
      retried++;
    } catch (err) {
      console.error(`Retry failed for order ${order.id}:`, err);
    }
  }

  return NextResponse.json({ retried, total: failedOrders.length });
}
