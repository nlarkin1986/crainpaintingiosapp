import { NextRequest, NextResponse } from 'next/server';
import { getStripe } from '@/lib/stripe';
import { CONSULTATION_PACKAGES } from '@/types/consultation';
import type { PackageType } from '@/types/consultation';

export const maxDuration = 10;

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { packageType, email, orderId } = body as {
      packageType: PackageType;
      email: string;
      orderId: string;
    };

    const pkg = CONSULTATION_PACKAGES[packageType];
    if (!pkg) {
      return NextResponse.json({ error: 'Invalid package type' }, { status: 400 });
    }

    if (!email || !orderId) {
      return NextResponse.json({ error: 'Email and order ID are required' }, { status: 400 });
    }

    const stripe = getStripe();

    const session = await stripe.checkout.sessions.create({
      ui_mode: 'embedded',
      customer_email: email,
      line_items: [
        {
          price_data: {
            currency: 'usd',
            product_data: {
              name: pkg.name,
              description: pkg.description,
            },
            unit_amount: pkg.priceCents,
          },
          quantity: 1,
        },
      ],
      mode: 'payment',
      return_url: `${request.nextUrl.origin}/consultation/status/${orderId}?session_id={CHECKOUT_SESSION_ID}`,
      metadata: {
        orderId,
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
