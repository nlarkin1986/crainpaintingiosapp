# Crain Paint Visualizer - Native iOS App Build Prompt

## Overview

Build a native iOS app (SwiftUI, iOS 17+) for **Crain Painting Contractors** that replicates and enhances their existing Next.js web app. The app lets homeowners photograph a room, pick Benjamin Moore or Sherwin-Williams paint colors, choose a surface, and see an AI-generated visualization of what that room would look like repainted. It also offers a paid Expert Color Consultation flow where a professional painter provides personalized color recommendations based on room type, lighting, mood preferences, and sun/window analysis.

---

## Core Features

### 1. Paint Visualizer (Main Flow - Free)

A 3-step wizard + results gallery:

**Step 1 - Pick Colors**
- Searchable color catalog with ~3,500 Benjamin Moore + ~1,800 Sherwin-Williams colors
- Colors stored locally as JSON (number, name, family, hex, brand)
- Brand toggle (Benjamin Moore / Sherwin-Williams tabs)
- Show 24 curated "popular" colors by default
- Search by name, number, or color family
- Multi-select: user can pick multiple colors (each generates a separate visualization)
- Color chips show hex swatch + name + number
- Selected colors shown as removable pills/chips

**Step 2 - Upload Photo**
- Camera capture or photo library picker
- Client-side image compression to max 4MB before upload
- Preview thumbnail of selected photo
- Replace photo option

**Step 3 - Choose Surface**
- Surface options: Exterior/Siding, Walls, Cabinets, Front Door, Trim, Ceiling, Shutters, Custom
- "Custom" option reveals a text field for freeform surface description (e.g., "just the accent wall behind the TV")
- Single-select (one surface at a time)

**Step 4 - Results Gallery**
- Generates one visualization per selected color (sequentially)
- Each result shows: pending -> generating (spinner) -> complete (before/after) or failed (retry)
- Before/after comparison slider (like react-compare-slider)
- Color info overlay (name, number, hex swatch)
- Share individual results (share sheet with image)
- "Add Another Color" returns to Step 1 keeping completed results
- "Start Over" resets everything
- Save results to a proposal (links to admin/client system)

### 2. Expert Color Consultation (Paid)

A multi-step flow where users get personalized color recommendations:

**Phase A - Style Quiz**
1. Room type picker (Living Room, Kitchen, Bedroom, Bathroom, Dining Room, Home Office, Hallway/Entryway, Exterior, Other)
2. Mood/vibe selector (Warm & Cozy, Clean & Modern, Bold & Dramatic, Calm & Serene, Classic & Timeless, Coastal & Airy)
3. AI-suggested colors based on room + mood (calls API, shows 6-8 suggestions). User can select favorites or request another round of suggestions ("Show me more like these")

**Phase B - Consultation Form**
- Photo upload (multiple photos)
- Surface type selection
- Window direction picker (N, NE, E, SE, S, SW, W, NW, "I don't know")
- Address input (geocoded via Google Maps API for sun position calculation)
- Email for delivery
- Package selection with Stripe checkout:
  - Quick Color Review: $49 (1 room, 2-3 recommendations, 24-48hr)
  - Detailed Color Analysis: $149 (up to 3 rooms, 4-5 recommendations, 2-3 days) - POPULAR
  - Whole Home Color Plan: $399 (unlimited rooms, 6-8 recommendations, 5-7 days)

**Report Delivery**
- AI-generated report (Claude API) with:
  - Executive summary
  - Color recommendations with rationale, finish/sheen specs
  - Time-of-day color shift analysis (morning/afternoon/evening hex values)
  - Before/after visualizations
  - Application tips and surface prep guide
- Viewable in-app and via web link
- PDF download option
- Sun position timeline visualization (sunrise, sunset, solar noon, golden hour)

### 3. Expert Landing Page

Marketing page for Curt Crain (the consultant):
- Hero with profile photo and credentials
- "About Curt" section (20+ years experience, fine artist, BM specialist)
- How It Works steps
- Package comparison cards
- Testimonials
- Bottom CTA

### 4. Admin Dashboard (iPad-optimized)

For the business owner to manage clients and proposals:
- Simple password auth (iron-session equivalent)
- Client list with search (trigram search)
- Client detail: name, address, linked proposals
- Proposal detail: title, notes, linked visualization results (before/after images, color info)
- Print-friendly proposal view
- Create/edit/delete clients and proposals

---

## Architecture

### API Layer
The app needs a backend. Two options:

**Option A (Recommended): Keep the existing Next.js API**
- The iOS app calls the same API endpoints the web app uses
- Endpoints to integrate with:
  - `POST /api/visualize` - upload image + color + surface, get back visualization
  - `POST /api/consultation/quiz` - get AI color suggestions
  - `POST /api/consultation/create-session` - create Stripe checkout
  - `POST /api/consultation/generate` - trigger report generation
  - `GET /api/consultation/report/[id]` - fetch completed report
  - `POST /api/consultation/geocode` - geocode address
  - `POST /api/consultation/sun-data` - get sun position data
  - CRUD: `/api/clients`, `/api/proposals`

**Option B: Rewrite backend in Swift (Vapor) or use Firebase**
- Only if you want to eliminate the web dependency entirely

### Data Models

```swift
struct PaintColor: Codable, Identifiable, Hashable {
    let number: String    // "HC-70"
    let name: String      // "Van Buren Brown"
    let family: String    // "Brown"
    let hex: String       // "5F4F46" (no # prefix)
    let brand: Brand

    var id: String { "\(brand.rawValue)-\(number)" }

    enum Brand: String, Codable {
        case benjaminMoore = "benjamin_moore"
        case sherwinWilliams = "sherwin_williams"
    }
}

enum VisualizationStatus {
    case pending
    case generating
    case complete(originalUrl: URL, resultUrl: URL, shareId: String)
    case failed(error: String)
}

struct ColorResult: Identifiable {
    let id = UUID()
    let color: PaintColor
    var status: VisualizationStatus
}

struct ConsultationOrder: Codable {
    let id: String
    let email: String
    let packageType: PackageType
    let priceCents: Int
    let paymentStatus: PaymentStatus
    let reportStatus: ReportStatus
    let quizResponses: QuizResponse
    let selectedColors: [String]
    let photoUrls: [String]
    let surfaceType: String
    let windowDirection: String
    let address: String
    let latitude: Double?
    let longitude: Double?
}

struct ColorRecommendation: Codable {
    let colorName: String
    let colorNumber: String
    let hex: String
    let rationale: String
    let finishSheen: String
    let morningHex: String
    let afternoonHex: String
    let eveningHex: String
    let visualizationUrl: String?
}

struct ConsultationReport: Codable {
    let id: String
    let orderId: String
    let executiveSummary: String
    let recommendations: [ColorRecommendation]
    let applicationTips: [String]
    let surfacePrep: [String]
    let sunData: SunData
}
```

### Key Technical Details

**AI Visualization Pipeline:**
1. User photo compressed client-side (max 4MB)
2. Uploaded to server with color + surface info
3. Server builds a specific paint prompt (see prompt templates below)
4. Sent to Gemini 2.5 Flash (image model) with the photo
5. Gemini returns edited image with only the specified surface repainted
6. Result stored in blob storage, URL returned to client

**Paint Prompt Templates (critical for quality):**
Each surface has a precise prompt that tells the AI exactly what to paint and what NOT to paint:
- Walls: "Repaint ONLY the wall surfaces... Do NOT paint trim, baseboards, crown molding, ceiling, doors, windows, floors, or fixtures"
- Cabinets: "Repaint ONLY the cabinet doors, drawer fronts, and face frames... Do NOT paint walls, countertops, backsplash, hardware, appliances"
- Exterior/Siding: "Repaint ONLY the exterior siding... Do NOT paint trim, windows, doors, shutters, roof, gutters, porch columns, foundation, sky, or landscaping"
- Front Door, Trim, Ceiling, Shutters each have similar specific prompts
- Custom: "Repaint ONLY the {user's custom description}..."

**Color Shift Algorithm:**
Calculates how paint appears at different times of day based on window direction:
- Morning: warm shift (+0.3 warmth)
- Afternoon: neutral (true color)
- Evening: very warm golden shift (+0.5 warmth)
- Direction modifiers: North = -0.2 (cooler), South = +0.2 (warmer), etc.
- Applied as RGB temperature shift with 0.08 intensity

**Rate Limiting:** IP-based, server-side (already handled by the API)

---

## Design System

### Colors (Light/Dark mode support)
Map from the web app's CSS variables:
- Background: white / zinc-950
- Foreground: zinc-950 / zinc-50
- Primary: zinc-900 / zinc-50
- Muted: zinc-100 / zinc-800
- Border: zinc-200 / zinc-800
- Destructive: red-500

### Typography
- Clean, minimal sans-serif (SF Pro / system default)
- Headers: semibold/bold
- Body: regular weight
- Color numbers in monospace where appropriate

### Components to Build
- StepProgress (horizontal step indicator with numbers)
- ColorChip (swatch + name + number, tappable)
- ColorSearchBar (instant search across catalog)
- PhotoUploadCard (camera/library picker with preview)
- SurfacePickerGrid (icon cards for each surface type)
- BeforeAfterSlider (drag-to-compare overlay)
- ResultCard (color info + before/after + share button)
- PackageCard (pricing card with feature list)
- QuizCard (room type, mood selector)
- SunTimeline (visual sunrise-to-sunset arc)
- TimeOfDaySwatches (morning/afternoon/evening color previews)

### Branding
- Logo: Crain Painting Contractors (load from assets)
- Tagline: "See your room in a new color"
- Footer: "Trusted since 1952"
- Expert: Curt Crain profile photo + credentials

---

## Navigation Structure

```
TabView {
    Tab 1: "Visualize" - Main paint visualizer wizard
    Tab 2: "Expert" - Consultation landing page + quiz/checkout
    Tab 3: "Admin" - Client/proposal management (could be behind auth)
}
```

Or a simpler structure:
```
NavigationStack {
    Home (Visualizer)
    -> Expert Consultation (push)
    -> Admin (push, authenticated)
}
```

---

## Third-Party Dependencies

- **Networking:** URLSession (built-in) or Alamofire
- **Image loading:** AsyncImage (built-in) or Kingfisher/SDWebImage for caching
- **Stripe:** stripe-ios SDK for payment
- **Camera/Photos:** PhotosUI (PHPickerViewController)
- **Image compression:** Built-in UIImage JPEG compression
- **Keychain:** For storing admin auth token
- **No database needed on-device** - all data lives on the server (Supabase/Vercel Postgres)

---

## Build Priorities

### Phase 1 - MVP (Paint Visualizer)
1. Color catalog with search (JSON bundled in app)
2. Photo capture/upload
3. Surface picker
4. API integration for visualization
5. Before/after results with comparison slider
6. Share results

### Phase 2 - Consultation Flow
1. Style quiz (room type, mood, AI suggestions)
2. Consultation form + photo upload
3. Stripe checkout integration
4. Report viewing

### Phase 3 - Admin & Polish
1. Admin dashboard
2. Client/proposal management
3. Push notifications for report completion
4. Offline color browsing
5. Recently viewed colors
6. Haptic feedback on interactions

---

## Existing SwiftUI Design System Guide

A detailed guide for translating the web app's Tailwind/shadcn design system to SwiftUI already exists at `SWIFTUI_DESIGN_SYSTEM_GUIDE.md` in this repo. It covers:
- Design token mapping (CSS variables -> Asset Catalog colors)
- Typography scale
- Component patterns (cards, buttons, badges, inputs, sheets)
- Layout patterns
- Animation/transition approaches
- Dark mode strategy

Reference that file when implementing the UI layer.

---

## Key Files to Reference in the Web Codebase

| Purpose | Web File |
|---|---|
| Main visualizer flow | `src/app/page.tsx` |
| Color types | `src/types/colors.ts` |
| Consultation types | `src/types/consultation.ts` |
| Paint prompt builder | `src/lib/prompt.ts` |
| Gemini integration | `src/lib/gemini.ts` |
| Claude report generation | `src/lib/claude.ts` |
| Color shift algorithm | `src/lib/color-shift.ts` |
| Sun analysis | `src/lib/sun-analysis.ts` |
| Visualize API | `src/app/api/visualize/route.ts` |
| Color catalog loader | `src/lib/colors.ts` |
| Consultation quiz | `src/app/consultation/page.tsx` |
| Expert landing page | `src/app/expert/page.tsx` |
| DB schema | `migrations/001_init.sql` |
| Design system guide | `SWIFTUI_DESIGN_SYSTEM_GUIDE.md` |
