# iOS Monetization and AI Notes

## Recommendation

Use two separate monetization surfaces:

1. **AI visualizations:** StoreKit 2 in-app purchase.
   - Launch with 5 free completed AI renders.
   - Gate only additional completed AI renders.
   - Recommended first SKU: non-consumable lifetime unlock, `com.crainpainting.visualizer.pro.lifetime`.
   - Suggested launch price: $19.99-$29.99. This is simpler than credits for homeowners, avoids subscription fatigue for an occasional home project, and stays easy to explain in the paywall.
   - Later option: add credit packs if Gemini cost or contractor usage requires tighter cost control.

2. **Expert consultation:** keep separate from visualization access.
   - If the package is a real human-reviewed service from Curt/Crain and substantially delivered as personal guidance, Stripe/Apple Pay can remain appropriate.
   - If the package is primarily an in-app AI-generated digital report, it should move to StoreKit/IAP to reduce App Store review risk.
   - Existing tiers can remain, but should be reframed:
     - $49 Quick Color Review: single room, human-reviewed notes.
     - $149 Video Consultation: best-value guided project review.
     - $399 Whole Home Plan: multi-room palette and contractor-ready guidance.

## App Store Compliance

Digital AI renders, saved digital reports, and digital-only subscriptions or credits consumed in the app should use StoreKit 2. Person-to-person real-time services and physical services consumed outside the app may use non-IAP purchase methods. The iOS app should avoid steering users to Stripe for digital-only visualization access.

## AI Model Strategy

The API keeps model IDs environment-configurable:

- `GEMINI_IMAGE_MODEL`
- `GEMINI_IMAGE_FALLBACK_MODEL`
- `GEMINI_IMAGE_SECONDARY_FALLBACK_MODEL`
- `CLAUDE_REPORT_MODEL`

Default image editing now starts with `gemini-2.5-flash-image`, which is the stable Gemini image-editing model documented by Google Cloud. Keep the newer preview image model as an environment-configured fallback only after validating availability, cost, and quota in the production Google project.

## Mobbin-Inspired Patterns Used

- Camera/library choice should be immediate and low-friction.
- AI result screens should disclose that generated results can vary and should provide compare, save, share, and regenerate/retry actions near the image.
- Paywalls should show the current plan/restore affordance plainly, with non-punitive copy and clear cancellation/Apple account management language.
- Color selection should use visible swatches, search/filter controls, and persistent selected-count feedback.
