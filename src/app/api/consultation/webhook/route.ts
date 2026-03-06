import { NextRequest, NextResponse } from 'next/server';
import type Stripe from 'stripe';
import { getStripe } from '@/lib/stripe';
import { createClient } from '@/lib/supabase/server';

export const maxDuration = 30;

async function triggerReportGeneration(orderId: string, request: NextRequest) {
  try {
    const baseUrl = process.env.NEXT_PUBLIC_APP_URL || request.nextUrl.origin;
    fetch(`${baseUrl}/api/consultation/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ orderId }),
    }).catch(err => {
      console.error('Failed to trigger report generation:', err);
    });
  } catch {
    // Non-blocking: cron will retry failed reports
    console.error('Failed to trigger report generation');
  }
}

async function markOrderPaid(
  orderId: string,
  request: NextRequest,
  metadata: { paymentIntentId?: string | null; sessionId?: string | null }
) {
  const supabase = await createClient();
  const { data: existingOrder } = await supabase
    .from('orders')
    .select('payment_status')
    .eq('id', orderId)
    .single();

  if (existingOrder?.payment_status === 'paid') {
    return NextResponse.json({ received: true, status: 'already_processed' });
  }

  const updateData: {
    payment_status: string;
    report_status: string;
    stripe_payment_intent_id?: string;
    stripe_session_id?: string;
    updated_at: string;
  } = {
    payment_status: 'paid',
    report_status: 'generating',
    updated_at: new Date().toISOString(),
  };

  if (metadata.paymentIntentId) {
    updateData.stripe_payment_intent_id = metadata.paymentIntentId;
  }
  if (metadata.sessionId) {
    updateData.stripe_session_id = metadata.sessionId;
  }

  const { error: updateError } = await supabase
    .from('orders')
    .update(updateData)
    .eq('id', orderId);

  if (updateError) {
    console.error('Failed to update order:', updateError);
    return NextResponse.json({ error: 'Failed to update order' }, { status: 500 });
  }

  await triggerReportGeneration(orderId, request);
  return null;
}

export async function POST(request: NextRequest) {
  const body = await request.text();
  const signature = request.headers.get('stripe-signature');

  if (!signature) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 });
  }

  const stripe = getStripe();
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!webhookSecret) {
    console.error('STRIPE_WEBHOOK_SECRET is not set');
    return NextResponse.json({ error: 'Webhook not configured' }, { status: 500 });
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const orderId = session.metadata?.orderId;
    const paymentIntentId = typeof session.payment_intent === 'string'
      ? session.payment_intent
      : session.payment_intent?.id;

    if (!orderId) {
      console.error('No orderId in session metadata');
      return NextResponse.json({ error: 'Missing order ID' }, { status: 400 });
    }

    const response = await markOrderPaid(orderId, request, {
      paymentIntentId,
      sessionId: session.id,
    });
    if (response) {
      return response;
    }
  }

  if (event.type === 'payment_intent.succeeded') {
    const paymentIntent = event.data.object as Stripe.PaymentIntent;
    const orderId = paymentIntent.metadata?.orderId;

    if (!orderId) {
      console.error('No orderId in payment intent metadata');
      return NextResponse.json({ error: 'Missing order ID' }, { status: 400 });
    }

    const response = await markOrderPaid(orderId, request, {
      paymentIntentId: paymentIntent.id,
    });
    if (response) {
      return response;
    }
  }

  return NextResponse.json({ received: true });
}
