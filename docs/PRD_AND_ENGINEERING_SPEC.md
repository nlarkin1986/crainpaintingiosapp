# Crain Paint Visualizer - iOS App
## Product Requirements Document & Engineering Specification

**Version**: 1.0
**Date**: March 5, 2026
**Status**: Draft - Ready for Review

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Product Overview](#2-product-overview)
3. [User Personas](#3-user-personas)
4. [Feature Specification](#4-feature-specification)
5. [Information Architecture](#5-information-architecture)
6. [Technical Architecture](#6-technical-architecture)
7. [Data Models](#7-data-models)
8. [API Integration Strategy](#8-api-integration-strategy)
9. [Design System](#9-design-system)
10. [Screen-by-Screen Specification](#10-screen-by-screen-specification)
11. [Payment Strategy](#11-payment-strategy)
12. [Offline & Caching Strategy](#12-offline--caching-strategy)
13. [Security](#13-security)
14. [Push Notifications](#14-push-notifications)
15. [PDF Generation](#15-pdf-generation)
16. [Development Phases](#16-development-phases)
17. [Dependencies & SDK Versions](#17-dependencies--sdk-versions)
18. [Risks & Mitigations](#18-risks--mitigations)
19. [Acceptance Criteria](#19-acceptance-criteria)
20. [Appendix: Web-to-iOS Component Mapping](#20-appendix-web-to-ios-component-mapping)

---

## 1. Executive Summary

### What We're Building

A native iOS app for **Crain Painting Contractors** (est. 1952) that converts their existing Next.js web application into a first-class iPhone experience. The app lets homeowners visualize paint colors on their rooms using AI-powered image generation, and offers paid expert color consultation packages with detailed lighting analysis reports.

### Why Native iOS

- **Camera-first experience**: The core flow is "take a photo of your room, see it painted." Native camera integration is dramatically better than web.
- **Offline color browsing**: 3,000+ Benjamin Moore and Sherwin-Williams colors available without network.
- **Push notifications**: Alert users when their paid consultation report is ready.
- **Apple Pay**: Frictionless payment for consultation packages.
- **App Store presence**: Discovery channel for a trusted 70+ year contractor brand.

### Source Web Application

- **Repository**: github.com/nlarkin1986/crainpaintingvisualizer35
- **Stack**: Next.js 16, React 19, Tailwind CSS 4, shadcn/ui, Supabase, Vercel
- **AI**: Google Gemini (image generation), Anthropic Claude (color consultation reports)
- **Payments**: Stripe (3 consultation tiers: $49, $149, $399)

### Target Platform

- **Minimum iOS**: 17.0
- **Devices**: iPhone (primary), iPad (stretch goal)
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Architecture**: MVVM with @Observable

---

## 2. Product Overview

### Core Value Propositions

| Feature | User Value | Business Value |
|---------|-----------|----------------|
| Paint Visualizer | See your room in a new color before buying paint | Lead generation for Crain Painting |
| Color Consultation | Expert AI-powered color recommendations with lighting analysis | Revenue ($49-$399 per consultation) |
| Expert Landing Page | Learn about Curt Crain's 20+ year expertise | Trust building, conversion funnel |
| Admin Dashboard | Manage client proposals and print reports | Operational efficiency |
| Sharing | Share before/after comparisons | Viral marketing, word of mouth |

### Feature Parity Matrix

| Web Feature | iOS App | Notes |
|-------------|---------|-------|
| Paint Visualizer (3-step wizard) | P0 - Launch | Core feature |
| Color Catalog (BM + SW, search, filter) | P0 - Launch | Offline-capable |
| Photo Upload (camera + library) | P0 - Launch | Native camera integration |
| Result Gallery (before/after slider) | P0 - Launch | Custom gesture-driven slider |
| Save Proposal | P0 - Launch | Via API to existing backend |
| Share Comparison | P0 - Launch | Native share sheet |
| Color Consultation Quiz | P1 - v1.1 | Room type, mood, AI suggestions |
| Consultation Form + Payment | P1 - v1.1 | Stripe/IAP hybrid |
| Consultation Report Viewer | P1 - v1.1 | Sun timeline, color recommendations |
| Expert Landing Page | P1 - v1.1 | Marketing/conversion |
| Admin Dashboard | P2 - v2.0 | Client list, proposals, print |
| Report Lookup by Email | P2 - v2.0 | For returning customers |
| Push Notifications | P1 - v1.1 | Report completion alerts |

---

## 3. User Personas

### Persona 1: Homeowner Hannah
- **Age**: 32-55
- **Goal**: Picking paint colors for a room renovation
- **Pain Point**: Can't visualize how a color will look in their specific room
- **Journey**: Opens app -> picks colors -> takes photo of room -> sees AI visualization -> shares with partner -> contacts Crain for estimate

### Persona 2: Design-Conscious Derek
- **Age**: 28-45
- **Goal**: Wants expert guidance on a whole-home color scheme
- **Pain Point**: Overwhelmed by 3,000+ color options, worried about lighting
- **Journey**: Takes color quiz -> gets AI suggestions -> uploads photos -> pays for consultation -> receives detailed report with time-of-day lighting analysis

### Persona 3: Contractor Curt (Admin)
- **Age**: 50+
- **Goal**: Manage client proposals and share visualizations during estimates
- **Pain Point**: Needs to quickly pull up past work and print proposals on-site
- **Journey**: Logs in -> searches clients -> views proposals -> prints/shares with client

---

## 4. Feature Specification

### 4.1 Paint Visualizer (P0)

**User Story**: As a homeowner, I want to upload a photo of my room, pick a paint color, and see an AI-generated visualization of my room in that color.

**Flow**:
```
Step 1: Pick Colors (1-5)
  -> Brand toggle (Benjamin Moore / Sherwin-Williams)
  -> Popular colors grid (24 curated per brand)
  -> Full catalog with search (name, number, hex)
  -> Family filter chips (horizontal scroll)

Step 2: Upload Photo
  -> Take Photo (native camera)
  -> Choose from Library (PhotosPicker)
  -> Auto-compression to <3.5MB, max 2048px
  -> Preview with "Change Photo" option

Step 3: Select Surface
  -> Preset grid: Walls, Cabinets, Front Door, Trim, Ceiling, Shutters, Exterior/Siding
  -> "Custom/Other" with text input field
  -> Context card showing photo thumbnail + selected colors

Step 4: Results Gallery
  -> Sequential generation (one color at a time)
  -> Progress: "Generating 1 of 5..."
  -> Before/after comparison slider per result
  -> Per-result actions: Download, Share, Remove
  -> Retry on failure (tap to retry)
  -> "Add Another Color" to go back to Step 1 with existing results preserved
  -> "Save as Proposal" (admin-only)
  -> "Start Over" to reset
```

**Acceptance Criteria**:
- [ ] User can select 1-5 colors from BM or SW catalog
- [ ] Camera capture works on all supported iPhones
- [ ] Photo is compressed before upload (target <3.5MB)
- [ ] Each visualization generates in <30 seconds
- [ ] Before/after slider is smooth at 60fps
- [ ] Results persist if user adds another color
- [ ] Rate limit handling shows user-friendly message
- [ ] Unsaved results prompt confirmation before leaving

### 4.2 Color Catalog (P0)

**Data**:
- Benjamin Moore: Full catalog (~3,500 colors)
- Sherwin-Williams: Full catalog (~1,800 colors)
- Each color: number, name, family, hex, brand

**Features**:
- Search by name, number, or hex code (case-insensitive)
- Filter by color family (horizontal scroll chips)
- Popular colors tab (24 curated per brand)
- Color swatch grid (2 columns on small phones, 3 on larger)
- Selection indicator (checkmark overlay on selected swatches)
- Max 5 colors with toast notification at limit

**Offline**: Color catalog bundled in app, loaded into SwiftData on first launch.

### 4.3 Photo Capture & Upload (P0)

**Camera Integration**:
- Native camera via `UIImagePickerController` wrapped in `UIViewControllerRepresentable`
- Rear camera by default (`sourceType: .camera`, `cameraDevice: .rear`)
- Permission prompt with `NSCameraUsageDescription`

**Photo Library**:
- SwiftUI `PhotosPicker` (iOS 16+)
- Filter: `.images` only
- Load as `Data.self` (not `Image.self` -- handles HEIC/JPEG properly)

**Image Processing Pipeline**:
1. Resize to max 2048px dimension
2. Convert to JPEG at 0.8 quality
3. Verify <3.5MB (iteratively reduce quality if needed)
4. Display preview
5. Upload as multipart form data to `/api/visualize`

### 4.4 Before/After Comparison Slider (P0)

**Implementation**: Custom SwiftUI view with `DragGesture`.

**Structure**:
- `ZStack` with original image (full width) and result image (masked)
- `Rectangle` mask controlled by drag position
- White divider line (2pt) with circular drag handle
- Labels: "Before" (left), "After" (right)
- Snap to edges if dragged past 90%

**Performance**: Images loaded via `AsyncImage` with `NSCache`-backed caching layer.

### 4.5 Color Consultation (P1)

**Quiz Phase**:
```
Step 0: Room Type Selection
  -> 9 room types as tappable cards with icons
  -> Living Room, Kitchen, Bedroom, Bathroom, Dining Room,
     Home Office, Hallway/Entryway, Exterior, Other

Step 1: Mood Selection
  -> 6 moods as cards with icon + description
  -> Warm & Cozy, Clean & Modern, Bold & Dramatic,
     Calm & Serene, Classic & Timeless, Coastal & Airy

Step 2: AI Color Suggestions
  -> Fetches 4-6 colors from Claude via /api/consultation/quiz
  -> Displays as selectable swatch cards with name + number
  -> "Show Me More" button for refinement rounds
  -> Selected colors carry forward to form
```

**Form Phase** (6 steps):
```
Step 0: Confirm Colors (add/remove from quiz selections)
Step 1: Upload Room Photos (1-10 photos via PhotosPicker)
Step 2: Room Details (surface type + window direction)
Step 3: Address (with geocode validation via API)
Step 4: Email
Step 5: Package Selection ($49 / $149 / $399)
  -> Proceed to Payment
```

**Payment**: See Section 11.

### 4.6 Consultation Report Viewer (P1)

**Sections**:
1. **Report Header**: Package type badge, date, room type
2. **Executive Summary**: 2-3 paragraph AI-written overview
3. **Color Recommendations**: Per-color cards with:
   - Large color swatch
   - Color name + BM number
   - Expert rationale (2-3 sentences)
   - Finish/sheen recommendation
   - Before/after visualization slider (if photos provided)
   - Time-of-day swatches (morning/afternoon/evening hex shifts)
4. **Lighting Analysis**: SVG-style sun timeline (sunrise -> solar noon -> golden hour -> sunset)
5. **Application Tips**: Bulleted preparation and application guidance
6. **Report Footer**: Download PDF, share link

### 4.7 Sharing (P0)

**Share a Visualization**:
- Native `ShareLink` with before/after composite image
- Deep link: `crainpaint://share/{shareId}`
- Fallback: web URL to `/share/{shareId}`

**Share a Report**:
- Token-protected URL
- Via native share sheet

### 4.8 Admin Dashboard (P2)

**Features**:
- Login with admin credentials (stored in Keychain)
- Client list with search (`.searchable()` modifier)
- Client detail with proposal list
- Proposal detail with before/after gallery
- Soft delete proposals
- Print/export proposal as PDF

**Navigation**: `NavigationSplitView` for master-detail on iPad, collapses to stack on iPhone.

---

## 5. Information Architecture

```
Tab Bar (3 tabs)
|
|-- Visualize (Tab 1 - Primary)
|   |-- Color Picker
|   |   |-- Brand Toggle
|   |   |-- Popular Colors Grid
|   |   |-- Full Catalog (Search + Family Filter)
|   |-- Photo Upload
|   |   |-- Camera Capture
|   |   |-- Photo Library
|   |   |-- Preview
|   |-- Surface Picker
|   |   |-- Preset Grid
|   |   |-- Custom Input
|   |-- Results Gallery
|       |-- Before/After Cards
|       |-- Save Proposal (Sheet)
|       |-- Share (ShareLink)
|
|-- Consult (Tab 2)
|   |-- Quiz Flow
|   |   |-- Room Type
|   |   |-- Mood
|   |   |-- AI Suggestions
|   |-- Form Flow
|   |   |-- Confirm Colors
|   |   |-- Upload Photos
|   |   |-- Room Details
|   |   |-- Address
|   |   |-- Email
|   |   |-- Package Selection
|   |-- Payment (Sheet)
|   |-- Status Polling
|   |-- Report Viewer
|
|-- More (Tab 3)
    |-- Expert Profile (Curt Crain)
    |-- My Reports (email lookup)
    |-- Admin Login (hidden/long-press)
    |-- Admin Dashboard
    |   |-- Client List
    |   |-- Client Detail
    |   |-- Proposal Detail
    |-- About / Contact
    |-- Settings
```

---

## 6. Technical Architecture

### 6.1 Architecture Pattern

**MVVM with @Observable** (iOS 17+)

```
View Layer (SwiftUI)
  |
  |-- @State var viewModel = FeatureViewModel()
  |
ViewModel Layer (@Observable, @MainActor)
  |
  |-- Holds UI state, business logic, calls services
  |
Service Layer (Protocols + Implementations)
  |
  |-- APIClient (URLSession + async/await)
  |-- ImageService (compression, caching)
  |-- PaymentService (Stripe SDK)
  |-- PersistenceService (SwiftData)
  |-- NotificationService (APNs)
  |-- KeychainManager (Security framework)
  |-- LocationService (CoreLocation)
```

### 6.2 Project Structure

```
CrainPaintVisualizer/
|-- App/
|   |-- CrainPaintVisualizerApp.swift      // @main, scene setup
|   |-- AppState.swift                      // @Observable global state
|   |-- AppRouter.swift                     // Tab + deep link routing
|
|-- Features/
|   |-- Visualizer/
|   |   |-- Views/
|   |   |   |-- VisualizerFlowView.swift    // NavigationStack host
|   |   |   |-- ColorPickerView.swift
|   |   |   |-- ColorCatalogView.swift
|   |   |   |-- ColorSwatchView.swift
|   |   |   |-- PopularColorsView.swift
|   |   |   |-- PhotoUploadView.swift
|   |   |   |-- CameraView.swift            // UIViewControllerRepresentable
|   |   |   |-- SurfacePickerView.swift
|   |   |   |-- ResultGalleryView.swift
|   |   |   |-- ResultCardView.swift
|   |   |   |-- ComparisonSliderView.swift
|   |   |   |-- SaveProposalSheet.swift
|   |   |-- ViewModels/
|   |   |   |-- VisualizerViewModel.swift
|   |   |   |-- ColorCatalogViewModel.swift
|   |
|   |-- Consultation/
|   |   |-- Views/
|   |   |   |-- ConsultationFlowView.swift
|   |   |   |-- RoomTypeView.swift
|   |   |   |-- MoodSelectionView.swift
|   |   |   |-- AISuggestionsView.swift
|   |   |   |-- ConsultationFormView.swift
|   |   |   |-- PackageSelectionView.swift
|   |   |   |-- PaymentView.swift
|   |   |   |-- StatusPollingView.swift
|   |   |   |-- ReportView.swift
|   |   |   |-- SunTimelineView.swift
|   |   |   |-- ColorRecommendationCard.swift
|   |   |   |-- TimeOfDaySwatches.swift
|   |   |-- ViewModels/
|   |   |   |-- ConsultationViewModel.swift
|   |   |   |-- ReportViewModel.swift
|   |
|   |-- Expert/
|   |   |-- ExpertProfileView.swift
|   |   |-- HeroSection.swift
|   |   |-- AboutSection.swift
|   |   |-- HowItWorksSection.swift
|   |   |-- PackageCardsSection.swift
|   |   |-- TestimonialsSection.swift
|   |
|   |-- Admin/
|   |   |-- Views/
|   |   |   |-- AdminLoginView.swift
|   |   |   |-- AdminDashboardView.swift
|   |   |   |-- ClientListView.swift
|   |   |   |-- ClientDetailView.swift
|   |   |   |-- ProposalDetailView.swift
|   |   |-- ViewModels/
|   |   |   |-- AdminViewModel.swift
|   |
|   |-- Sharing/
|   |   |-- ShareComparisonView.swift
|   |   |-- ShareLinkGenerator.swift
|
|-- Core/
|   |-- Networking/
|   |   |-- APIClient.swift                 // Protocol + URLSession impl
|   |   |-- Endpoints.swift                 // All API endpoint definitions
|   |   |-- MultipartFormData.swift         // Image upload helper
|   |
|   |-- Services/
|   |   |-- ImageService.swift              // Compression + caching
|   |   |-- PaymentService.swift            // Stripe integration
|   |   |-- NotificationService.swift       // APNs registration
|   |   |-- LocationService.swift           // Geocoding
|   |   |-- SunCalculationService.swift     // Port of suncalc logic
|   |   |-- ColorShiftService.swift         // Time-of-day color shifts
|   |
|   |-- Persistence/
|   |   |-- Models/
|   |   |   |-- CachedColor.swift           // SwiftData @Model
|   |   |   |-- SavedVisualization.swift     // SwiftData @Model
|   |   |   |-- DraftConsultation.swift      // SwiftData @Model
|   |   |-- ColorCatalogStore.swift          // Bulk import + query
|   |
|   |-- Keychain/
|   |   |-- KeychainManager.swift
|   |
|   |-- Utilities/
|       |-- ImageCompressor.swift
|       |-- HexColor.swift                   // Color from hex string
|       |-- Constants.swift
|
|-- DesignSystem/
|   |-- Colors.swift                         // Color.appPrimary, etc.
|   |-- Typography.swift                     // Font.heading(), Font.body()
|   |-- Components/
|   |   |-- AppButton.swift                  // Button variants
|   |   |-- AppCard.swift                    // Card container
|   |   |-- AppBadge.swift                   // Badge component
|   |   |-- AppInput.swift                   // Styled TextField
|   |   |-- ShimmerModifier.swift            // Loading skeleton
|   |   |-- ToastModifier.swift              // Toast overlay
|   |   |-- StepProgressView.swift           // Wizard progress dots
|
|-- Resources/
|   |-- Assets.xcassets/                     // Colors, images, app icon
|   |-- Data/
|   |   |-- bm-colors.json                  // Benjamin Moore catalog
|   |   |-- sw-colors.json                  // Sherwin-Williams catalog
|   |-- Fonts/
|   |   |-- OpenSans-*.ttf
|   |   |-- MerriweatherSans-*.ttf
|   |-- Localizable.strings
```

### 6.3 Architecture Diagram

```
+-------------------------------------------------------+
|                    iOS App                              |
|  +--------------------------------------------------+  |
|  |  SwiftUI Views                                    |  |
|  |  (Visualizer | Consultation | Expert | Admin)     |  |
|  +--------------------------------------------------+  |
|  |  @Observable ViewModels                           |  |
|  |  (UI state, business logic, service orchestration)|  |
|  +--------------------------------------------------+  |
|  |  Service Layer                                    |  |
|  |  +-------------+ +------------+ +---------------+ |  |
|  |  | APIClient   | | ImageSvc   | | PaymentSvc    | |  |
|  |  | (URLSession)| | (compress, | | (Stripe SDK)  | |  |
|  |  |             | |  cache)    | |               | |  |
|  |  +------+------+ +-----+------+ +------+--------+ |  |
|  |  +-------------+ +------------+ +---------------+ |  |
|  |  | SwiftData   | | Keychain   | | Location +    | |  |
|  |  | (colors,    | | (tokens)   | | SunCalc       | |  |
|  |  |  drafts)    | |            | |               | |  |
|  |  +-------------+ +------------+ +---------------+ |  |
|  +--------------------------------------------------+  |
+------------------------+------------------------------+
                         |
                   HTTPS + JWT
                         |
+------------------------v------------------------------+
|              Next.js API Routes (BFF)                  |
|  POST /api/visualize     (proxy -> Gemini)             |
|  POST /api/consultation/quiz  (proxy -> Claude)        |
|  POST /api/consultation/generate (Claude + Gemini)     |
|  POST /api/consultation/create-session (Stripe)        |
|  POST /api/consultation/geocode (Google Maps)          |
|  POST /api/proposals     (Vercel Postgres)             |
|  GET  /api/clients       (Vercel Postgres)             |
|  POST /api/admin/auth    (Iron Session)                |
|  POST /api/consultation/webhook (Stripe webhook)       |
+-------------------------------------------------------+
|  External Services                                     |
|  Gemini | Claude | Stripe | Supabase | Google Maps     |
|  Resend | Vercel Blob | Vercel Postgres                |
+-------------------------------------------------------+
```

### 6.4 Hybrid Backend Strategy

**Direct SDK connections from iOS**:
| Service | SDK | Why Direct |
|---------|-----|-----------|
| Supabase | supabase-swift | Auth, DB queries, file storage. RLS protects data. |
| Firebase/Gemini | Firebase AI Logic SDK | Image generation with App Check protection. |

**Through BFF (Next.js API routes)**:
| Service | Why Proxied |
|---------|-------------|
| Anthropic Claude | API key must stay server-side |
| Stripe secret operations | PaymentIntent creation must be server-side |
| Google Maps Geocoding | Protect API key |
| Resend email | Server-only concern |
| Vercel Blob | No iOS SDK available |
| Vercel Postgres (admin) | Admin-only, server-authenticated |

**Authentication for mobile**:
- Supabase Auth for customer-facing features (email/password or Apple Sign-In)
- JWT token attached to all BFF API calls
- Iron Session continues for web admin; mobile admin uses JWT + Keychain

---

## 7. Data Models

### 7.1 Swift Models

```swift
// MARK: - Colors

struct PaintColor: Codable, Hashable, Identifiable {
    let number: String      // "HC-70"
    let name: String        // "Van Buren Brown"
    let family: String      // "Brown"
    let hex: String         // "5F4F46" (no # prefix)
    let brand: PaintBrand

    var id: String { "\(brand.rawValue)-\(number)" }
    var uiColor: Color { Color(hex: hex) }
}

enum PaintBrand: String, Codable, CaseIterable {
    case benjaminMoore = "benjamin_moore"
    case sherwinWilliams = "sherwin_williams"

    var displayName: String {
        switch self {
        case .benjaminMoore: return "Benjamin Moore"
        case .sherwinWilliams: return "Sherwin-Williams"
        }
    }
}

// MARK: - Visualizer

enum VisualizationStatus: Equatable {
    case pending
    case generating
    case complete(originalURL: URL, resultURL: URL, shareId: String)
    case failed(error: String)
}

struct VisualizationResult: Identifiable {
    let id = UUID()
    let color: PaintColor
    var status: VisualizationStatus
}

enum SurfaceType: String, CaseIterable {
    case walls = "Walls"
    case cabinets = "Cabinets"
    case frontDoor = "Front Door"
    case trim = "Trim"
    case ceiling = "Ceiling"
    case shutters = "Shutters"
    case exteriorSiding = "Exterior / Siding"
    case custom = "Custom / Other"
}

// MARK: - Consultation

enum RoomType: String, CaseIterable {
    case livingRoom = "Living Room"
    case kitchen = "Kitchen"
    case bedroom = "Bedroom"
    case bathroom = "Bathroom"
    case diningRoom = "Dining Room"
    case homeOffice = "Home Office"
    case hallway = "Hallway / Entryway"
    case exterior = "Exterior"
    case other = "Other"
}

enum MoodOption: String, CaseIterable {
    case warmCozy = "warm_cozy"
    case cleanModern = "clean_modern"
    case boldDramatic = "bold_dramatic"
    case calmSerene = "calm_serene"
    case classicTimeless = "classic_timeless"
    case coastalAiry = "coastal_airy"

    var label: String { /* ... */ }
    var description: String { /* ... */ }
    var iconName: String { /* ... */ }
}

enum WindowDirection: String, CaseIterable {
    case n = "N", ne = "NE", e = "E", se = "SE"
    case s = "S", sw = "SW", w = "W", nw = "NW"
    case unknown = "unknown"

    var label: String { /* ... */ }
    var description: String { /* ... */ }
}

struct ConsultationPackage: Identifiable {
    let key: PackageType
    let name: String
    let description: String
    let priceCents: Int
    let priceDisplay: String
    let turnaround: String
    let roomCount: String
    let features: [String]
    let isPopular: Bool

    var id: String { key.rawValue }
}

enum PackageType: String, Codable {
    case quickReview = "quick_review"           // $49
    case videoConsultation = "video_consultation" // $149
    case wholeHome = "whole_home"               // $399
}

// MARK: - Report

struct ColorRecommendation: Codable, Identifiable {
    let colorName: String
    let colorNumber: String
    let hex: String
    let rationale: String
    let finishSheen: String
    let morningHex: String
    let afternoonHex: String
    let eveningHex: String
    let visualizationUrl: String?
    let originalUrl: String?

    var id: String { colorNumber }
}

struct SunData: Codable {
    let sunrise: String
    let sunset: String
    let solarNoon: String
    let goldenHour: String
    let sunPath: [SunPosition]
    let dayLengthHours: Double
    let lightingAnalysis: String
}

struct SunPosition: Codable {
    let time: String
    let altitude: Double
    let azimuth: Double
    let isVisible: Bool
}

struct ConsultationReport: Codable, Identifiable {
    let id: String
    let orderId: String
    let accessToken: String
    let executiveSummary: String
    let recommendations: [ColorRecommendation]
    let sunData: SunData
    let applicationTips: [String]
    let surfacePrep: [String]
    let pdfUrl: String?
    let createdAt: String
}

// MARK: - Admin / Proposals

struct Client: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let createdAt: String
}

struct Proposal: Codable, Identifiable {
    let id: String
    let clientId: String
    let title: String?
    let notes: String?
    let deletedAt: String?
    let createdAt: String
}

struct ProposalResult: Codable, Identifiable {
    let id: String
    let proposalId: String
    let shareId: String
    let originalUrl: String
    let resultUrl: String
    let colorName: String
    let colorNumber: String
    let colorHex: String
    let brand: String
    let surface: String?
    let createdAt: String
}
```

### 7.2 SwiftData Models (Persistence)

```swift
@Model
final class CachedColor {
    @Attribute(.unique) var colorId: String  // "benjamin_moore-HC-70"
    var number: String
    var name: String
    var family: String
    var hex: String
    var brand: String
    var lastSynced: Date

    init(from color: PaintColor) {
        self.colorId = color.id
        self.number = color.number
        self.name = color.name
        self.family = color.family
        self.hex = color.hex
        self.brand = color.brand.rawValue
        self.lastSynced = Date()
    }
}

@Model
final class SavedVisualization {
    var id: UUID
    var originalImagePath: String   // Local file path
    var resultImagePath: String?    // Local file path
    var colorNumber: String
    var colorName: String
    var colorHex: String
    var brand: String
    var surface: String
    var shareId: String?
    var createdAt: Date

    init(/* ... */) { /* ... */ }
}

@Model
final class DraftConsultation {
    var id: UUID
    var roomType: String?
    var mood: String?
    var selectedColorNumbers: [String]
    var surfaceType: String?
    var windowDirection: String?
    var address: String?
    var email: String?
    var packageType: String?
    var lastModified: Date

    init() {
        self.id = UUID()
        self.selectedColorNumbers = []
        self.lastModified = Date()
    }
}
```

---

## 8. API Integration Strategy

### 8.1 API Client

```swift
protocol APIClientProtocol: Sendable {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func upload(imageData: Data, to endpoint: APIEndpoint, fields: [String: String]) async throws -> VisualizationResponse
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let body: (any Encodable)?
    let queryItems: [URLQueryItem]?

    enum HTTPMethod: String { case GET, POST, PUT, DELETE }
}
```

### 8.2 Endpoint Catalog

```swift
extension APIEndpoint {
    // Visualizer
    static func visualize() -> APIEndpoint {
        .init(path: "/api/visualize", method: .POST, body: nil, queryItems: nil)
    }

    // Consultation
    static func quizSuggestions(roomType: String, mood: String, selectedColors: [String], round: Int) -> APIEndpoint {
        .init(path: "/api/consultation/quiz", method: .POST,
              body: QuizRequest(roomType: roomType, mood: mood, selectedColors: selectedColors, round: round),
              queryItems: nil)
    }

    static func generateReport(orderId: String) -> APIEndpoint {
        .init(path: "/api/consultation/generate", method: .POST,
              body: ["orderId": orderId], queryItems: nil)
    }

    static func createPaymentSession(packageType: String, email: String, orderId: String) -> APIEndpoint {
        .init(path: "/api/consultation/create-session", method: .POST,
              body: CreateSessionRequest(packageType: packageType, email: email, orderId: orderId),
              queryItems: nil)
    }

    static func geocode(address: String) -> APIEndpoint {
        .init(path: "/api/consultation/geocode", method: .POST,
              body: ["address": address], queryItems: nil)
    }

    // Proposals
    static func saveProposal(_ payload: SaveProposalPayload) -> APIEndpoint {
        .init(path: "/api/proposals", method: .POST, body: payload, queryItems: nil)
    }

    static func listProposals(clientId: String?) -> APIEndpoint {
        var items: [URLQueryItem] = []
        if let clientId { items.append(.init(name: "clientId", value: clientId)) }
        return .init(path: "/api/proposals", method: .GET, body: nil, queryItems: items)
    }

    // Admin
    static func adminLogin(password: String) -> APIEndpoint {
        .init(path: "/api/admin/auth", method: .POST, body: ["password": password], queryItems: nil)
    }

    static func searchClients(query: String) -> APIEndpoint {
        .init(path: "/api/clients", method: .GET, body: nil,
              queryItems: [.init(name: "q", value: query)])
    }
}
```

### 8.3 Image Upload (Multipart)

```swift
func uploadVisualization(
    imageData: Data,
    color: PaintColor,
    surface: String,
    customInstruction: String?
) async throws -> VisualizationResponse {
    let boundary = UUID().uuidString
    var body = Data()

    // Image field
    body.appendMultipart(name: "image", filename: "room.jpg",
                         contentType: "image/jpeg", data: imageData, boundary: boundary)
    // Text fields
    body.appendMultipart(name: "colorName", value: color.name, boundary: boundary)
    body.appendMultipart(name: "colorHex", value: color.hex, boundary: boundary)
    body.appendMultipart(name: "colorNumber", value: color.number, boundary: boundary)
    body.appendMultipart(name: "surface", value: surface, boundary: boundary)
    body.appendMultipart(name: "brand", value: color.brand.rawValue, boundary: boundary)
    if let instruction = customInstruction {
        body.appendMultipart(name: "customInstruction", value: instruction, boundary: boundary)
    }
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)

    var request = URLRequest(url: baseURL.appendingPathComponent("/api/visualize"))
    request.httpMethod = "POST"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    let (data, response) = try await URLSession.shared.upload(for: request, from: body)
    // Handle response...
}
```

### 8.4 Rate Limit Handling

```swift
actor APIThrottler {
    private var requestTimestamps: [Date] = []
    private let maxRequests: Int
    private let windowSeconds: TimeInterval

    init(maxRequests: Int = 10, windowSeconds: TimeInterval = 60) {
        self.maxRequests = maxRequests
        self.windowSeconds = windowSeconds
    }

    func shouldAllow() -> Bool {
        let now = Date()
        requestTimestamps.removeAll { now.timeIntervalSince($0) > windowSeconds }
        guard requestTimestamps.count < maxRequests else { return false }
        requestTimestamps.append(now)
        return true
    }
}
```

Server returns `X-RateLimit-Remaining` header. On 429 response:
- Show toast: "Rate limit reached. Try again in a few minutes."
- Skip remaining queued visualizations
- Use exponential backoff on retry (1s, 2s, 4s, 8s)

---

## 9. Design System

### 9.1 Color Tokens

```swift
extension Color {
    // Primary palette
    static let appPrimary = Color(hex: "27CCC0")         // Teal
    static let appAccent = Color(hex: "F6653C")           // Orange-red
    static let appBackground = Color(hex: "FAFAFA")       // Off-white
    static let appForeground = Color(hex: "0F172A")       // Dark navy
    static let appCard = Color.white
    static let appMuted = Color(hex: "F0F0F0")
    static let appBorder = Color(hex: "E2E8F0")
    static let appDestructive = Color(hex: "EF4444")

    // Semantic
    static let appMutedForeground = Color(hex: "64748B")
    static let appPrimaryForeground = Color.white
    static let appAccentForeground = Color.white
}
```

### 9.2 Typography

```swift
extension Font {
    static func heading(_ size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        .custom("MerriweatherSans-Bold", size: size)
    }

    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        .custom("OpenSans-Regular", size: size)
    }

    static func bodyMedium(_ size: CGFloat = 16) -> Font {
        .custom("OpenSans-SemiBold", size: size)
    }

    static func caption(_ size: CGFloat = 12) -> Font {
        .custom("OpenSans-Regular", size: size)
    }
}
```

### 9.3 Component Library

| Web Component | iOS Component | Implementation |
|---------------|---------------|----------------|
| `<Button variant="default">` | `AppButton(.primary)` | Filled, appPrimary background |
| `<Button variant="outline">` | `AppButton(.outline)` | Border-only, appBorder stroke |
| `<Button variant="ghost">` | `AppButton(.ghost)` | No border, transparent bg |
| `<Button variant="cta">` | `AppButton(.cta)` | Gradient, appAccent -> appPrimary |
| `<Card>` | `AppCard { }` | White bg, 16pt corners, shadow |
| `<Badge variant="outline">` | `AppBadge(text:)` | Capsule with stroke |
| `<Input>` | `AppInput` | 48pt height, rounded, border |
| `<Skeleton>` | `.shimmer()` modifier | Gradient animation on `.redacted()` |
| Sonner toast | `.toast()` modifier | Custom overlay with auto-dismiss |
| `<StepProgress>` | `StepProgressView` | Horizontal dots with connector lines |
| Color swatch grid | `LazyVGrid` + `ColorSwatchCell` | Adaptive 2-3 columns |
| Before/after slider | `ComparisonSliderView` | DragGesture + mask |
| react-compare-slider | `ComparisonSliderView` | Custom implementation |

### 9.4 Corner Radii

```swift
extension CGFloat {
    static let cornerSm: CGFloat = 8
    static let cornerMd: CGFloat = 12
    static let cornerLg: CGFloat = 16
    static let cornerXl: CGFloat = 20
}
```

### 9.5 Spacing Scale

Uses 4pt grid: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

---

## 10. Screen-by-Screen Specification

### 10.1 Color Picker Screen

**Layout**:
- Header: "See your room in a new color" + Crain logo
- Brand toggle: Segmented control (Benjamin Moore | Sherwin-Williams)
- Tab bar: "Popular" | "All Colors"
- Popular tab: LazyVGrid, 2 columns, 24 color swatches
- All Colors tab:
  - Search bar (48pt height, magnifying glass icon, clear button)
  - Family filter: Horizontal ScrollView of pill buttons
  - Results count: "247 colors"
  - LazyVGrid, 2-3 columns (adaptive min 150pt)
- Bottom sticky bar (`.safeAreaInset(edge: .bottom)`):
  - Selected colors as small circles
  - "Next" button (disabled until >= 1 color selected)

**Color Swatch Cell**:
- Rounded rectangle filled with color (aspect ratio 1:1 top, label below)
- Color name (14pt, medium weight)
- Color number (12pt, muted)
- Checkmark overlay when selected
- Disabled state (opacity 0.4) when at 5-color max

### 10.2 Photo Upload Screen

**Layout**:
- Header: "Upload a Photo" + subtitle
- Card container:
  - Empty state: Drag zone (not applicable on iOS) + two buttons:
    - "Take Photo" (Camera icon, native camera launch)
    - "From Library" (Image icon, PhotosPicker)
  - Photo selected: Full-width image preview + "Change Photo" button
  - Compressing state: Spinner + "Preparing your photo..."
- Navigation: Back button + Next button (disabled until photo selected)

### 10.3 Surface Picker Screen

**Layout**:
- Header: "What should we paint?"
- 2x4 grid of surface buttons (with SF Symbol icons):
  - paintbrush (Walls), cabinet (Cabinets), door (Front Door)
  - ruler (Trim), square.3.layers (Ceiling), blinds.horizontal (Shutters)
  - house (Exterior/Siding), ellipsis.circle (Custom/Other)
- If "Custom" selected: Text field appears with placeholder "Describe the surface..."
- Context card: Thumbnail of uploaded photo + color pills
- Navigation: Back + "Visualize" button (accent gradient)

### 10.4 Results Gallery Screen

**Layout**:
- Progress banner (during generation): "Generating visualization 1 of 3..."
- Vertical scroll of result cards:
  - Each card: ComparisonSliderView (before/after) + color info bar
  - Color info: Swatch circle + name + number + surface label
  - Action buttons: Download (arrow.down.circle), Share (square.and.arrow.up), Remove (xmark)
  - Failed state: Error message + "Tap to Retry"
- Bottom action bar:
  - "Add Another Color" (outline button)
  - "Save as Proposal" (primary button, admin only)
  - "Start Over" (ghost button)
- Saved success banner: Green checkmark + "Proposal saved" + link

### 10.5 Consultation Quiz Screens

**Room Type** (full-screen cards):
- 3x3 grid of room type cards
- Each: SF Symbol icon + room name + subtle description
- Selected state: Primary border + tinted background

**Mood Selection**:
- 2x3 grid of mood cards
- Each: Icon + label + short description
- Selected state: Same as room type

**AI Suggestions**:
- Header message from AI (e.g., "Here are some colors we think you'll love")
- Loading state: 4-6 skeleton swatch cards with shimmer
- Suggestion cards: Large swatch + name + number + toggle button
- "Show Me More" button (outline, triggers refinement round)
- "Continue" button (when >= 1 color selected)
- Skip link: "Skip to form" (if colors already selected)

### 10.6 Consultation Report Screen

**Layout** (scrollable):
- Report header card: Package badge, date, room type
- Executive Summary card: Multi-paragraph text
- Color Recommendations section:
  - Per-color cards with:
    - Large color swatch (full width, 80pt height)
    - Name + BM number
    - Rationale text
    - Finish/sheen badge
    - Before/after slider (if visualization available)
    - Time-of-day row: 3 color circles (morning/afternoon/evening) with labels
- Lighting Analysis card:
  - Sun timeline (custom Canvas/Shape drawing)
  - 4 markers: Sunrise, Solar Noon, Golden Hour, Sunset
  - Day length display
  - Written lighting analysis text
- Application Tips card: Bulleted list
- Surface Prep card: Bulleted list
- Footer: Download PDF button + Share button

---

## 11. Payment Strategy

### 11.1 Apple IAP vs Stripe Analysis

**Critical Decision**: Apple requires In-App Purchase (IAP) for digital content and services consumed within the app.

The Crain consultation reports are **AI-generated digital content** (not a 1:1 human service), which means Apple will likely require IAP.

### 11.2 Recommended Approach: IAP for Launch, Hybrid Later

**Phase 1 (Launch)**: Apple IAP via StoreKit 2
- 3 products registered in App Store Connect:
  - `com.crainpainting.consultation.quick` ($49)
  - `com.crainpainting.consultation.detailed` ($149)
  - `com.crainpainting.consultation.wholehome` ($399)
- Apple takes 15-30% commission
- Zero risk of App Store rejection

**Phase 2 (Post-Launch)**: Add external purchase link
- Under the post-Epic v. Apple ruling, add a link to the web checkout
- Users can choose: IAP in-app OR Stripe on web
- Must still offer IAP as an option

**Phase 3 (If consultation adds human element)**: Pure Stripe
- If Curt Crain personally reviews each consultation, it qualifies as a person-to-person service (Section 3.1.3(d))
- External payment is then fully allowed

### 11.3 StoreKit 2 Integration

```swift
@Observable
@MainActor
final class PaymentService {
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []

    func loadProducts() async {
        let productIDs = [
            "com.crainpainting.consultation.quick",
            "com.crainpainting.consultation.detailed",
            "com.crainpainting.consultation.wholehome"
        ]
        products = try? await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Notify your server to create the order
            await notifyServer(transaction: transaction, productId: product.id)
            await transaction.finish()
            return transaction
        case .userCancelled, .pending:
            return nil
        @unknown default:
            return nil
        }
    }
}
```

### 11.4 Server-Side Verification

After IAP purchase, the iOS app sends the transaction to your Next.js backend:
```
POST /api/consultation/verify-purchase
{
  "transactionId": "...",
  "productId": "com.crainpainting.consultation.detailed",
  "email": "user@example.com",
  "quizResponses": { ... },
  "selectedColors": [...],
  "photoUrls": [...],
  "surfaceType": "Walls",
  "windowDirection": "S",
  "address": "123 Main St..."
}
```

Server verifies with Apple's App Store Server API, creates the order in Supabase, and triggers report generation.

---

## 12. Offline & Caching Strategy

### 12.1 What Works Offline

| Feature | Offline Support | How |
|---------|----------------|-----|
| Color browsing (catalog) | Full | SwiftData with bundled JSON |
| Color search/filter | Full | Local SwiftData queries |
| Photo capture | Full | Photos saved locally |
| Image compression | Full | On-device processing |
| Visualization generation | No | Requires Gemini API |
| Consultation quiz | No | Requires Claude API |
| Report viewing | Cached | Cache once loaded |
| Saved visualizations | Full | Stored in SwiftData |

### 12.2 Color Catalog Sync

1. **First launch**: Import `bm-colors.json` and `sw-colors.json` from app bundle into SwiftData
2. **Background refresh**: Weekly check against API for catalog updates
3. **Query**: Use `@Query` with predicates for search/filter:
```swift
@Query(filter: #Predicate<CachedColor> { $0.brand == "benjamin_moore" },
       sort: \CachedColor.name)
var bmColors: [CachedColor]
```

### 12.3 Image Caching

- `AsyncImage` handles basic URL caching
- Custom `NSCache`-backed `ImageCache` actor for visualization results
- Downloaded report visualizations cached to disk via `FileManager`
- Cache eviction: LRU, max 200MB

### 12.4 Draft Consultation Persistence

If user is mid-consultation form and leaves the app, save draft to SwiftData:
```swift
@Model final class DraftConsultation { ... }
```
Resume on next launch with prompt: "You have an unfinished consultation. Continue?"

---

## 13. Security

### 13.1 API Key Management

**Embedded in app (safe with protections)**:
| Key | Protection |
|-----|-----------|
| Supabase anon key | Row Level Security (RLS) |
| Stripe publishable key | Cannot make charges |
| Firebase config | Firebase App Check |

**Server-side only (never in app)**:
| Key | Reason |
|-----|--------|
| Anthropic/Claude API key | Full API access, billed per token |
| Stripe secret key | Can create charges |
| Google Maps API key | Billed per request |
| Supabase service_role key | Bypasses all RLS |
| Resend API key | Can send email |

### 13.2 Key Storage

- Tier 1 keys: `.xcconfig` file excluded from git, injected at build time
- Auth tokens: iOS Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Admin credentials: Keychain + optional biometric auth (`LAContext`)

### 13.3 Network Security

- All traffic over HTTPS (enforced by ATS)
- Certificate pinning for API endpoints (recommended, not required)
- JWT tokens expire after 1 hour; refresh tokens stored in Keychain

---

## 14. Push Notifications

### 14.1 Use Case

When a paid consultation report finishes generating (typically 2-5 minutes), push a notification:

**Title**: "Your Color Report is Ready"
**Body**: "Tap to view your personalized color recommendations for your Living Room."
**Action**: Deep link to report viewer: `crainpaint://report/{reportId}?token={accessToken}`

### 14.2 Implementation

1. Request permission after payment (contextually appropriate moment)
2. Register device token with backend: `POST /api/register-device`
3. Backend sends push via APNs when report generation completes
4. Use token-based APNs auth (`.p8` key) - does not expire annually
5. Handle notification tap -> parse deep link -> navigate to report

### 14.3 Local Notification Fallback

If user denies push permission, use local polling + local notification:
- Poll order status every 5 seconds while app is foregrounded
- Schedule local notification if app goes to background during generation

---

## 15. PDF Generation

### 15.1 Report PDF

Use `UIGraphicsPDFRenderer` for multi-page consultation report PDFs:

**Page 1 - Cover**:
- Crain Painting logo
- "Color Consultation Report"
- Package type, date, client name
- Room type

**Page 2 - Executive Summary**:
- Full executive summary text
- Key statistics (day length, window direction)

**Pages 3-N - Color Recommendations** (1 per page):
- Large color swatch (full width)
- Color name + number + brand
- Rationale text
- Finish/sheen
- Time-of-day color shift swatches
- Before/after images (if available)

**Page N+1 - Lighting Analysis**:
- Sun timeline graphic (rendered via Core Graphics)
- Written analysis

**Page N+2 - Application Tips**:
- Surface prep steps
- Application tips

**Footer (all pages)**: "Crain Painting Contractors - Trusted since 1952" + page number

### 15.2 Proposal PDF

Simpler format for admin proposal export:
- Client name + address
- Grid of before/after image pairs
- Color info per pair (name, number, hex, surface)

---

## 16. Development Phases

### Phase 1: MVP (P0) - 6-8 weeks
**Goal**: Ship the Paint Visualizer to the App Store

| Week | Deliverables |
|------|-------------|
| 1-2 | Project setup, design system, SwiftData color catalog, color picker UI |
| 3-4 | Camera/photo integration, image compression, surface picker |
| 5-6 | API client, visualization generation, results gallery, comparison slider |
| 7 | Save proposal flow, sharing, deep links |
| 8 | Polish, testing, App Store submission |

**Launch Features**:
- Full paint visualizer (pick colors -> photo -> surface -> AI visualization)
- Color catalog with search/filter (BM + SW, offline)
- Before/after comparison slider
- Save as proposal
- Share visualizations
- Basic branding (Crain logo, colors, typography)

### Phase 2: Consultation (P1) - 4-6 weeks
**Goal**: Add paid consultation service

| Week | Deliverables |
|------|-------------|
| 1-2 | Consultation quiz (room type, mood, AI suggestions) |
| 3 | Consultation form (photos, details, address, email) |
| 4 | StoreKit 2 IAP integration, purchase flow |
| 5 | Report viewer, sun timeline, PDF generation |
| 6 | Push notifications, status polling, testing |

### Phase 3: Admin & Polish (P2) - 3-4 weeks
**Goal**: Full admin dashboard, refinements

| Week | Deliverables |
|------|-------------|
| 1-2 | Admin login, client list, proposal detail, search |
| 3 | Expert profile page, report lookup, iPad layout |
| 4 | Performance optimization, accessibility audit, App Store update |

### Total Estimated Timeline: 13-18 weeks

---

## 17. Dependencies & SDK Versions

### Swift Package Manager Dependencies

| Package | SPM URL | Version | Purpose |
|---------|---------|---------|---------|
| Supabase Swift | `github.com/supabase/supabase-swift` | 2.0+ | Auth, DB, Storage |
| Stripe iOS | `github.com/stripe/stripe-ios-spm` | Latest | PaymentSheet (Phase 2 backup) |
| Firebase iOS | `github.com/firebase/firebase-ios-sdk` | 11.13+ | Gemini image gen via Firebase AI Logic |

### Apple System Frameworks (No SPM Needed)

| Framework | Purpose |
|-----------|---------|
| SwiftUI | UI layer |
| SwiftData | Local persistence |
| PhotosUI | Photo picker |
| AVFoundation | Camera capture |
| CoreLocation | User location for sun calculations |
| StoreKit | In-app purchases |
| UserNotifications | Push notifications |
| PDFKit | PDF viewing |
| Security | Keychain access |
| LocalAuthentication | Biometric auth (admin) |

### Build Requirements

- **Xcode**: 16.2+
- **Swift**: 6.0
- **iOS Deployment Target**: 17.0
- **Apple Developer Account**: Required (push notifications, IAP, App Store)

---

## 18. Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|------------|------------|
| **Apple rejects Stripe for consultation payments** | High - must rebuild payment flow | High | Launch with StoreKit 2 IAP from day one |
| **Gemini API latency on cellular** | Medium - poor UX | Medium | Show progress animation, allow background generation, cache results |
| **generative-ai-swift deprecated** | High - no Gemini on iOS | Already happened | Use Firebase AI Logic SDK (replacement) |
| **Large color catalog slows app launch** | Medium - poor first impression | Low | Lazy load into SwiftData, use bundled JSON |
| **App Store review delays** | Medium - timeline slip | Medium | Submit early, have no IAP in v1 if needed |
| **Camera permission denied** | Low - feature degraded | Low | Graceful fallback to photo library only |
| **Rate limiting blocks power users** | Medium - frustration | Medium | Client-side throttling, queue visualizations, cache results |
| **Supabase RLS misconfiguration** | Critical - data leak | Low | Thorough RLS policy review before launch |
| **iOS 17 adoption too low** | Medium - limited audience | Very Low | iOS 17+ is 90%+ of active devices in 2026 |

---

## 19. Acceptance Criteria

### P0 Launch Checklist

- [ ] User can browse 3,000+ colors offline with search and filter
- [ ] User can switch between Benjamin Moore and Sherwin-Williams
- [ ] User can select 1-5 colors with visual feedback
- [ ] User can take a photo with native camera
- [ ] User can select a photo from their library
- [ ] Photo is compressed to <3.5MB automatically
- [ ] User can select a surface type (7 presets + custom)
- [ ] Custom surface accepts text input
- [ ] Visualization generates successfully via Gemini API
- [ ] Before/after comparison slider works smoothly
- [ ] Multiple visualizations generate sequentially with progress
- [ ] Failed visualizations show error with retry option
- [ ] User can download visualization to camera roll
- [ ] User can share visualization via native share sheet
- [ ] User can save results as a proposal (admin)
- [ ] App handles rate limiting gracefully (429 response)
- [ ] App works on iPhone SE (3rd gen) through iPhone 16 Pro Max
- [ ] App supports Dynamic Type accessibility
- [ ] App supports light mode (dark mode stretch goal)
- [ ] No crashes on low memory conditions
- [ ] All network calls have timeout handling
- [ ] App icon, splash screen, and App Store metadata ready

### P1 Consultation Checklist

- [ ] Quiz flow: room type -> mood -> AI suggestions works end-to-end
- [ ] AI color suggestions load in <5 seconds
- [ ] Refinement rounds generate new suggestions
- [ ] Form captures all required data (colors, photos, surface, window, address, email)
- [ ] Address geocoding validates and formats address
- [ ] IAP purchase flow completes successfully
- [ ] Server receives purchase verification and creates order
- [ ] Report generates within 5 minutes of payment
- [ ] Push notification received when report is ready
- [ ] Report displays all sections (summary, colors, lighting, tips)
- [ ] Sun timeline renders correctly
- [ ] Time-of-day color swatches display correctly
- [ ] PDF download works
- [ ] Draft consultation persists if app is closed mid-form

---

## 20. Appendix: Web-to-iOS Component Mapping

### Full Component Translation Table

| Web (React/Tailwind/shadcn) | iOS (SwiftUI) | Notes |
|------------------------------|---------------|-------|
| `<Button variant="default">` | `Button { } .buttonStyle(PrimaryButtonStyle())` | Custom ButtonStyle |
| `<Button variant="outline">` | `Button { } .buttonStyle(OutlineButtonStyle())` | Stroke border |
| `<Button variant="ghost">` | `Button { } .buttonStyle(GhostButtonStyle())` | Transparent bg |
| `<Button variant="cta">` | `Button { } .buttonStyle(CTAButtonStyle())` | Gradient bg |
| `<Card>` | `VStack { }.background(.white).cornerRadius(16).shadow()` | Custom container |
| `<Badge>` | `Text("").font(.caption).padding(.horizontal, 8).overlay(Capsule().stroke())` | Inline |
| `<Input>` | `TextField("", text: $val).textFieldStyle(AppTextFieldStyle())` | Custom style |
| `<Skeleton>` | `Rectangle().redacted(reason: .placeholder).shimmer()` | Custom modifier |
| `Sonner` (toast) | Custom `.toast()` ViewModifier | Overlay + timer |
| `<StepProgress>` | `HStack { ForEach(steps) { StepDot() } }` | Custom |
| `LazyVGrid` (color grid) | `LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))])` | Built-in |
| `react-compare-slider` | `ComparisonSliderView` (custom) | ZStack + DragGesture + mask |
| `next/image` (Image optimization) | `AsyncImage(url:)` + `NSCache` layer | Custom caching |
| `useEffect` (lifecycle) | `.task { }` / `.onAppear { }` | SwiftUI equivalents |
| `useState` | `@State` | Direct mapping |
| `useRef` | `@State` (for values) or `let ref = Ref()` pattern | No direct equivalent |
| `fetch()` API calls | `URLSession.shared.data(for:)` | async/await |
| `FormData` (multipart) | Custom `Data` builder | Manual boundary encoding |
| `AbortController` | `Task.cancel()` | Swift concurrency |
| `useCallback` | Not needed | SwiftUI handles this |
| `useMemo` | Computed properties or `.onChange` | Declarative |
| `window.addEventListener('beforeunload')` | `@Environment(\.scenePhase)` | Scene lifecycle |
| `navigator.share()` | `ShareLink` or `UIActivityViewController` | Native share sheet |
| Tailwind responsive (`sm:`, `md:`) | `GeometryReader` + `@Environment(\.horizontalSizeClass)` | Adaptive layout |
| `className={cn(...)}` conditional styles | Ternary in modifiers: `.foregroundColor(isActive ? .primary : .gray)` | Inline |
| Radix UI primitives | SwiftUI built-ins (Toggle, Picker, Sheet) | Native equivalents |

### Navigation Mapping

| Web Route | iOS Screen | Navigation Type |
|-----------|-----------|----------------|
| `/` (home) | `VisualizerFlowView` | Tab 1 root |
| `/visualize` | Redirects to `/` | N/A |
| `/consultation` | `ConsultationFlowView` | Tab 2 root |
| `/consultation/status/[id]` | `StatusPollingView` | Push |
| `/consultation/report/[id]` | `ReportView` | Push or deep link |
| `/consultation/lookup` | `ReportLookupView` | Push from More tab |
| `/expert` | `ExpertProfileView` | Tab 3 content |
| `/share/[id]` | `ShareComparisonView` | Deep link / modal |
| `/admin` | `AdminDashboardView` | Push from More tab |
| `/admin/login` | `AdminLoginView` | Sheet |
| `/admin/dashboard` | `AdminDashboardView` | Push |
| `/admin/clients/[id]` | `ClientDetailView` | Push |
| `/admin/proposals/[id]` | `ProposalDetailView` | Push |
| `/admin/proposals/[id]/print` | PDF generation + share | Action sheet |

---

*This document was generated by analyzing the complete Crain Paint Visualizer Next.js codebase (github.com/nlarkin1986/crainpaintingvisualizer35) using parallel research agents covering: SwiftUI architecture, iOS design systems, API integration strategy, codebase deep dive, and framework documentation lookup.*

*Recommended next step: Review this spec, then begin Phase 1 development with the project structure defined in Section 6.2.*
