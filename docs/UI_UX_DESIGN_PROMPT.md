# Crain Paint Visualizer - iOS App UI/UX Design Prompt

---

## The Brief

Design a complete, production-ready iOS app for **Crain Painting Contractors** (established 1952). The app lets homeowners visualize paint colors on their rooms using AI, and purchase expert color consultation packages. We are converting an existing web app into a native iPhone experience. Design every screen at **390x844pt** (iPhone 14/15 size) with proper safe areas.

---

## Brand Identity

**Company**: Crain Painting Contractors - a trusted, 70+ year family painting business
**Expert**: Curt Crain - professional painter, fine artist, Benjamin Moore specialist with 20+ years experience
**Logo**: Existing logo at `/public/crain-logo.png` (use as provided, do not redesign)
**Tone**: Professional yet approachable. Trusted craftsmanship. Not trendy or flashy - established and reliable.
**Tagline**: "See your room in a new color"

---

## Design System

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| **Primary** | `#27CCC0` | Teal - buttons, selected states, icons, progress indicators, links |
| **Accent** | `#F6653C` | Orange-red - CTA gradients, "Most Popular" badges, attention-grabbing elements |
| **Background** | `#FAFAFA` | Off-white - app background, page backgrounds |
| **Foreground** | `#0F172A` | Dark navy - primary text, headings |
| **Card** | `#FFFFFF` | White - card backgrounds, elevated surfaces |
| **Muted** | `#F0F0F0` | Light gray - secondary backgrounds, disabled states, dividers |
| **Muted Foreground** | `#64748B` | Slate - secondary text, descriptions, placeholders |
| **Border** | `#E2E8F0` | Light border - card borders, dividers, input borders |
| **Destructive** | `#EF4444` | Red - errors, delete actions, failed states |
| **Input** | `#F8FAFC` | Very light blue-gray - input field backgrounds |
| **Ring** | `#27CCC0` | Teal - focus ring on interactive elements |

### CTA Gradient
Primary call-to-action buttons use a linear gradient from `#F6653C` (accent/orange) to `#27CCC0` (primary/teal), left to right. This is the "visualize" / "get report" / "proceed to payment" button style.

### Typography

| Style | Font | Size | Weight | Usage |
|-------|------|------|--------|-------|
| **Large Title** | Merriweather Sans | 28-32pt | Bold | Screen titles, hero text |
| **Title** | Merriweather Sans | 22-24pt | Bold | Section headings |
| **Headline** | Merriweather Sans | 18-20pt | Bold | Card titles, color names |
| **Body** | Open Sans | 16pt | Regular | Primary body text |
| **Body Medium** | Open Sans | 16pt | SemiBold | Emphasized body text |
| **Subhead** | Open Sans | 14pt | Medium | Button labels, color numbers |
| **Caption** | Open Sans | 12pt | Regular | Secondary info, timestamps |
| **Micro** | Open Sans | 10-11pt | Medium | Labels, hex codes, badges |

### Corner Radii
- **Small (sm)**: 8pt - badges, small chips
- **Medium (md)**: 12pt - buttons, inputs, small cards
- **Large (lg)**: 16pt - main cards, modals
- **Extra Large (xl)**: 20pt - hero elements, full-width cards

### Spacing
4pt grid system: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64

### Elevation / Shadows
- **Card shadow**: 0 1px 3px rgba(0,0,0,0.06), 0 1px 2px rgba(0,0,0,0.04)
- **Elevated shadow** (modals, popovers): 0 4px 16px rgba(0,0,0,0.08), 0 2px 8px rgba(0,0,0,0.04)
- **Selected state shadow**: 0 0 0 2px #27CCC0 (primary ring)

### Iconography
Use SF Symbols throughout. Map from the web app's Lucide icons:
- Palette -> paintpalette
- Camera -> camera
- Layers -> square.3.layers.3d
- PaintRoller -> paintbrush
- Home -> house
- DoorOpen -> door.left.hand.open
- ArrowUpFromDot -> arrow.up.circle
- Search -> magnifyingglass
- Check -> checkmark
- X -> xmark
- Download -> arrow.down.circle
- Share -> square.and.arrow.up
- ChevronRight -> chevron.right
- ArrowLeft -> chevron.left
- Loader/Spinner -> Use native ProgressView
- Flame -> flame
- Sparkles -> sparkles
- Zap -> bolt
- Leaf -> leaf
- Crown -> crown
- Waves -> water.waves
- Sun -> sun.max
- Sunrise -> sunrise
- Sunset -> sunset
- Star -> star
- MessageSquare -> message
- CreditCard -> creditcard
- MapPin -> mappin
- Mail -> envelope
- Compass -> safari (or location.north)
- Upload -> arrow.up.doc
- Plus -> plus
- RotateCcw -> arrow.counterclockwise

---

## App Structure (Tab Bar)

**3 tabs** in a standard iOS tab bar:

| Tab | Label | Icon | Root Screen |
|-----|-------|------|-------------|
| 1 | Visualize | paintbrush | Paint Visualizer Wizard |
| 2 | Consult | sparkles | Color Consultation |
| 3 | More | ellipsis.circle | Expert Profile + Settings |

The tab bar uses the standard iOS style with the Primary teal (`#27CCC0`) for the selected tab tint.

---

## Screens to Design

### SCREEN 1: Color Picker (Visualize Tab - Step 1 of 3)

**Header area**:
- Crain logo (centered, ~180pt wide, above step indicator)
- Subtitle: "See your room in a new color" in 14pt muted foreground, centered below logo

**Step Progress Indicator**:
- 3 steps shown horizontally: "Color" (paintpalette icon) -> "Photo" (camera icon) -> "Surface" (square.3.layers.3d icon)
- Each step is a 40x40pt circle with icon inside
- Current step: Primary teal border, teal tint background at 10% opacity, teal icon
- Completed step: Filled primary teal circle, white checkmark icon
- Future step: Muted gray fill, muted gray icon
- Connecting lines between circles: 2pt lines, muted gray for incomplete, primary teal for complete segments
- Step labels below each circle: "Color", "Photo", "Surface" in 12pt

**Brand Toggle** (Segmented Control):
- Full-width segmented control with 2 segments: "Benjamin Moore" | "Sherwin-Williams"
- Standard iOS segmented control appearance
- 16pt horizontal padding from screen edges

**Sub-tabs**: "Popular" | "All Colors" as a secondary tab bar (text tabs with underline indicator)

**Popular Colors Tab**:
- `LazyVGrid` with 2 columns, 12pt spacing
- Each swatch cell:
  - Rounded rectangle (full width, 64pt height) filled with the paint color
  - Below: Color name in 14pt medium foreground, centered
  - Below that: Color number in 12pt muted foreground, centered
  - Border: 2pt, normally `#E2E8F0` (border), on selection `#27CCC0` (primary) with a 2pt ring offset
  - Selected state: Checkmark icon overlay (white, with semi-transparent black overlay on the color rectangle)
  - Disabled state (at 5-color max): 40% opacity
  - Minimum cell height: 120pt total (64pt color + labels)

**All Colors Tab**:
- Search bar: 48pt height, magnifying glass icon left, "Search by name, number, or hex..." placeholder, clear (X) button when active. Background: `#F8FAFC`. Border radius: 12pt. Font size: 16pt (prevents iOS zoom)
- Below search: Horizontal scroll of family filter pills (capsule buttons, 40pt height). Selected pill: filled primary teal with white text. Unselected: outline border with foreground text. Families: White, Gray, Blue, Green, Beige, Brown, etc.
- Results count: "247 colors" in 14pt muted foreground
- Same grid as Popular but can show hundreds of items (use lazy loading)

**Bottom Sticky Bar** (pinned to safe area bottom):
- Background: Card white with subtle top border (`#E2E8F0`)
- Left: Row of selected color circles (28pt diameter each, with subtle border), scrollable if many
- Right: "Next" button (primary teal, 48pt height, "Next" + chevron.right icon)
- Disabled state when no colors selected (opacity 0.4)
- Badge on colors showing count: "3 selected" in micro text

---

### SCREEN 2: Photo Upload (Step 2 of 3)

**Step Progress**: Same indicator, now step 2 is current (step 1 shows completed checkmark)

**Header**:
- "Upload a Photo" in 22pt bold heading font
- "Take a picture or choose from your library" in 16pt muted foreground

**Upload Card** (white card, 16pt corners):

*Empty State*:
- Central upload area: Dashed 2pt border (muted), 16pt border radius
- Centered: Circle (56pt) with primary teal tint background, upload arrow icon in teal
- Below icon: "Drag & drop a photo here" in 16pt medium foreground
- Below: "or tap to browse your files" in 14pt muted foreground
- Below the dashed area: 2-column grid of option buttons:
  - "Take Photo": Card with camera icon (in teal-tinted 40pt circle) + label. 12pt border radius, subtle border
  - "From Library": Card with image icon (in accent-tinted 40pt circle) + label. Same style

*Compressing State*:
- Native ProgressView spinner (large, primary teal)
- "Preparing your photo..." in 16pt muted foreground

*Photo Selected State*:
- Full-width photo preview (fills card width, natural aspect ratio)
- Below photo: "Change Photo" button (outline style, full width, 48pt height)

**Navigation**:
- "Back" button (outline, chevron.left + "Back") on left
- "Next" button (primary, "Next" + chevron.right, flex-1) on right
- Both 48pt height

---

### SCREEN 3: Surface Picker (Step 3 of 3)

**Step Progress**: Step 3 current, steps 1-2 completed

**Header**:
- "Select Surface" in 22pt bold heading
- "Which surface would you like to visualize?" in 16pt muted foreground

**Context Reminder Card** (white card, inline):
- Row layout: Photo thumbnail (56x56pt, 12pt radius, border) | "Your selections" label (micro, uppercase, tracking-wide) + row of color circles (28pt each) + "3 colors" count

**Surface Grid** (inside a white card):
- 2x4 grid of surface buttons (80pt height each, 12pt gap):
  - Each button: SF Symbol icon (20pt) centered above label text (14pt medium)
  - Normal: 2pt border (border color), white background
  - Selected: 2pt primary border, primary/5% tint background, primary-colored icon and text
  - Press animation: scale(0.98)
  - Surfaces with icons:
    - house -> "Exterior / Siding"
    - paintbrush -> "Walls"
    - square.grid.2x2 -> "Cabinets"
    - door.left.hand.open -> "Front Door"
    - minus -> "Trim"
    - arrow.up.circle -> "Ceiling"
    - sidebar.left -> "Shutters"
    - pencil -> "Custom / Other"
- When "Custom / Other" is selected: Text input slides in below the grid (48pt height, 16pt font, placeholder: "e.g., garage door, fence, brick exterior...")

**Navigation**:
- "Back" (outline) on left
- CTA gradient button: "See My Room" (or "See My 3 Colors" if multiple). Full CTA gradient (`#F6653C` -> `#27CCC0`), white text, 48pt height, flex-1

---

### SCREEN 4: Results Gallery (Step 4 - Full Screen)

**No step indicator** - this is the results view

**Progress Banner** (shown during generation):
- Horizontal bar at top: Primary teal background at 10%, "Generating visualization 1 of 3..." in 14pt medium foreground
- Small ProgressView spinner inline

**Result Cards** (scrollable vertical list):

*Generating/Pending Card*:
- 4:3 aspect ratio shimmer placeholder (gradient animation: muted -> primary at 8% opacity -> muted, sliding left to right)
- Spinner overlay (if actively generating): 48pt white circle with ProgressView
- Status label: "Creating..." in capsule badge
- Below image: Color info bar - 40pt color square (rounded 8pt) + color name (14pt semibold) + color number (12pt muted)

*Completed Card*:
- Before/After comparison slider (4:3 aspect ratio):
  - Left half: original photo
  - Right half: AI-painted result
  - Vertical white divider line (2pt) at drag position
  - Circular drag handle (32pt, white fill, 2pt primary teal border, left-right arrow icon in teal)
  - "BEFORE" label: top-left, capsule badge (black at 60% opacity, white text, 10pt uppercase)
  - "AFTER" label: top-right, capsule badge (white at 80% opacity, dark text, 10pt uppercase)
  - Drag gesture controls the divider position
- Below slider: Color info row:
  - 40x40pt color swatch (rounded 8pt, subtle border + shadow)
  - Color name (14pt semibold) + color number (12pt muted) stacked
  - Right side: 3 icon buttons (36pt each, ghost style):
    - arrow.down.circle (download)
    - square.and.arrow.up (share)
    - xmark (remove, muted foreground, destructive on hover)

*Failed Card*:
- 4:3 area with muted/30% background
- Centered: Red-tinted circle (48pt) with arrow.counterclockwise icon
- Error text: "Something went wrong. Tap to retry." in 14pt muted
- "Retry" outline button below

**Bottom Action Bar** (sticky, white background, top border):
- "Add Another Color" (outline button, plus icon)
- "Save as Proposal" (primary button) - only shown for admin users
- "Start Over" (ghost button, smaller text)

**Saved Success Banner**:
- When proposal saved: Green-tinted banner slides in at top
- Checkmark icon + "Proposal saved" + link text

---

### SCREEN 5: Consultation Quiz - Room Type

**Top**: Quiz progress bar (thin horizontal bar, 4pt height, showing step 1 of 3)
- Background: muted gray track
- Fill: primary teal, animates width

**Content**:
- "What room are you painting?" in 28pt bold heading, centered
- "This helps us suggest the right colors" in 16pt muted foreground, centered

**Room Type Grid**: 3x3 grid of cards (equal height, 12pt gap)
- Each card: 12pt border radius, 2pt border, centered content
  - SF Symbol icon (24pt, muted foreground, primary when selected)
  - Room name below (14pt medium)
  - Selected: primary border, primary/10% tint background
  - Rooms:
    - bed.double -> "Bedroom"
    - sofa -> "Living Room"
    - fork.knife -> "Kitchen"
    - shower -> "Bathroom"
    - chair.lounge -> "Dining Room"
    - desktopcomputer -> "Home Office"
    - door.left.hand.open -> "Hallway / Entryway"
    - house -> "Exterior"
    - ellipsis.circle -> "Other"

**Skip link** (if user already has colors): "Skip to form ->" right-aligned, 14pt muted, underlined

---

### SCREEN 6: Consultation Quiz - Mood Selection

**Progress bar**: Step 2 of 3

**Content**:
- "What vibe are you going for?" in 28pt bold heading
- "Choose the mood that best describes your ideal space" in 16pt muted foreground

**Mood Cards**: 2-column grid (or 1-column on smaller phones), 12pt gap
- Each card: Minimum 72pt height, 12pt border radius, 2pt border, left-aligned content
  - HStack: SF Symbol icon (28pt, in a tinted circle) + VStack of label (16pt semibold) + description (14pt muted)
  - Selected: primary border, primary/10% background, primary icon color
  - Normal: border color, white background
  - Moods:
    - flame -> "Warm & Cozy" / "Rich tones, inviting atmosphere"
    - sparkles -> "Clean & Modern" / "Crisp whites, cool neutrals"
    - bolt -> "Bold & Dramatic" / "Deep colors, high contrast"
    - leaf -> "Calm & Serene" / "Soft pastels, natural tones"
    - crown -> "Classic & Timeless" / "Traditional palettes, enduring style"
    - water.waves -> "Coastal & Airy" / "Ocean blues, sandy neutrals"

---

### SCREEN 7: Consultation Quiz - AI Color Suggestions

**Progress bar**: Step 3 of 3

**AI Message**: Rounded card with subtle primary tint border, containing the AI's message text (e.g., "Here are some colors we think you'll love for your warm, cozy bedroom"). 14pt body text.

**Loading State**: 4-6 skeleton swatch cards in a 2-column grid, shimmer animation

**Suggestion Cards** (2-column grid):
- Each card: Larger than the catalog swatches
  - Color rectangle (80pt height, full width, rounded top)
  - Below: Color name (14pt semibold) + number (12pt muted)
  - Toggle button: Primary teal filled when selected (checkmark), outline when not ("Add" text or plus icon)

**Actions**:
- "Show Me More" button (outline, full width) - triggers new AI suggestions
- "Continue with X colors" button (primary, full width) - proceeds to form
- Both at bottom with 12pt gap

---

### SCREEN 8: Consultation Form (6-step scrollable form)

**Progress bar**: "Step 1 of 6" text + "Confirm Colors" label + thin fill bar

Each step animates in with a fade + 8pt upward slide (0.3s ease-out).

**Step 0 - Confirm Colors**:
- "Confirm Your Colors" heading
- "These colors will guide our recommendations" subtext
- Selected colors as badge pills (capsule, outline border, color circle + name + X remove button)
- "Add Color" outline button -> reveals inline search input with dropdown results

**Step 1 - Upload Photos**:
- "Upload Room Photos" heading
- "Photos help us analyze your lighting and space (1-10 photos)" subtext
- Empty: Full camera upload zone (dashed border, camera icon, "Upload room photos")
- With photos: 3-column grid of photo thumbnails with X remove buttons, plus "Add Photo" placeholder tile

**Step 2 - Room Details**:
- "Room Details" heading
- "Surface Type" label + 2x3 grid of selectable buttons (same style as main surface picker but smaller)
- "Window Direction" label with compass icon + 2x3 grid (+ "I don't know" spanning full width):
  - Each: Direction label (bold) + description (12pt muted) stacked
  - N, NE, E, SE, S, SW, W, NW, "I don't know"

**Step 3 - Address**:
- "Your Address" heading
- "We use your address to calculate how sunlight enters your room throughout the day" subtext
- Privacy note: "We never share or sell your information." in 12pt muted
- Input row: TextField (flex-1) + Validate button (outline, mappin icon)
  - Loading: spinner in validate button
  - Validated: green checkmark in validate button + "Address verified" green text below

**Step 4 - Email**:
- "Your Email" heading
- "We'll send your color report to this email" subtext
- Large email input (48pt height, 16pt font, envelope icon)

**Step 5 - Package Selection**:
- "Choose Your Package" heading
- 3 package cards stacked vertically (12pt gap):
  - Each card: 2pt border, 16pt radius
  - "Most Popular" badge: Accent orange capsule, positioned -12pt above card, centered
  - Popular card: Thicker primary/30% border, subtle shadow, primary/2% background
  - Layout per card:
    - HStack: Package name (18pt bold heading) | Price ("$149" in 20pt bold primary)
    - Description (14pt muted)
    - Scope + turnaround ("Up to 3 rooms . 3-5 business days" in 12pt muted)
  - Selected state: Primary border, primary/5% background

**Sticky Bottom Navigation** (every step):
- Background: white/95% opacity + blur
- Top border: subtle border at 50% opacity
- "Back" outline button (left, chevron.left icon + "Back")
- "Continue" primary button (right, "Continue" + chevron.right) - or "Proceed to Payment" (CTA gradient + creditcard icon) on final step
- Disabled when validation fails (opacity 0.4)

---

### SCREEN 9: Consultation Report Viewer

**Full scrollable page** (no tabs visible, dedicated view):

**Report Header Card**:
- Package type badge (e.g., "Detailed Color Analysis" in capsule, primary tint)
- Date generated
- Room type + mood labels
- Crain logo (small, bottom right of card)

**Executive Summary Card**:
- "Executive Summary" section heading (18pt bold)
- Multi-paragraph body text (14pt, foreground at 85% opacity, relaxed line height)

**Color Recommendations Section**:
- "Color Recommendations" heading

*Per-Color Card* (repeated for each recommendation):
- CardHeader: Large color swatch (64-80pt square, rounded 12pt, border, shadow) next to VStack:
  - "Recommendation 1" in micro muted uppercase
  - Color name in 18pt bold heading
  - Color number in 14pt primary medium
- "Why This Color" label (micro, uppercase, muted, with palette icon)
- Rationale paragraph (14pt, foreground/85%)
- Finish row: droplets icon + "Recommended finish:" muted + "Eggshell" bold
- Before/After Slider (same as results gallery slider, 4:3 aspect)
- "How Light Changes This Color" label
- **Time-of-Day Swatches**: 3 equal-width columns:
  - Each: Color rectangle (aspect 3:2, rounded, border) + icon + label ("Morning"/"Afternoon"/"Evening") + description ("Cool, soft light") + hex code in mono font
  - Morning: sunrise icon. Afternoon: sun.max icon. Evening: sunset icon.

**Lighting Analysis Card**:
- sun.max icon in amber + "Lighting Analysis" heading
- **Sun Timeline**: Horizontal bar visualization:
  - Full-width rounded bar with gradient fill (yellow -> amber -> orange, left to right)
  - 4 circular markers on the bar: Sunrise (yellow), Solar Noon (amber, larger), Golden Hour (orange), Sunset (orange)
  - Labels above each marker: "Sunrise", "Solar Noon", "Golden Hour", "Sunset" in 10pt medium
  - Times below each marker in 10pt muted
  - Golden hour segment has an overlay highlight (orange at 35% opacity)
  - Below bar: "11.2 hours of daylight" centered in 12pt muted
- Written lighting analysis paragraph below

**Application Tips Card**:
- "Preparation & Application" heading
- Bulleted list of surface prep steps
- Bulleted list of application tips
- Each bullet: Primary teal checkmark icon + text (14pt)

**Report Footer**:
- "Download PDF" button (primary, full width, document icon)
- "Share Report" button (outline, full width, share icon)
- "Crain Painting Contractors - Trusted since 1952" footer text

---

### SCREEN 10: Expert Profile (More Tab)

**Scrollable marketing page**:

**Hero Section**:
- White background, generous padding (80pt top)
- "Expert Color Consultant" capsule badge (outline, muted tint)
- Curt Crain profile photo (112pt circle, 4pt border in border color)
- "Curt Crain" in 36pt bold heading
- Bio text: "Professional painter, fine artist, and color expert with 20+ years transforming spaces across residential and commercial projects." in 18pt muted foreground
- Credential badges row: "Commercial & Residential", "Fine Artist", "Benjamin Moore Specialist" (outline capsules, subtle shadow)
- CTA buttons: "Get Your Color Report" (CTA gradient, 48pt) + "Try the Visualizer Free" (ghost, underlined)

**How It Works Section** (muted background):
- "How It Works" heading
- 3 numbered steps with icons and descriptions (vertical stack on mobile)

**Package Cards Section** (white background):
- "Consultation Packages" heading
- "Choose the level of guidance that fits your project" subtext
- 3 vertically stacked cards (on iPhone):
  - Same layout as Step 5 form but expanded with full feature lists
  - Each feature: Checkmark icon (primary) + feature text
  - "Most Popular" badge on middle card
  - CTA button per card

**Testimonials Section** (muted background):
- "What Clients Say" heading
- Horizontally scrollable cards with quote text, client name, star rating

**Bottom CTA Section**:
- "Ready to Transform Your Space?" heading
- CTA button + "Or try the free visualizer" link

---

### SCREEN 11: Status Polling (After Payment)

**Centered, minimal design**:
- Crain logo at top
- Large animated progress indicator:
  - 4-stage vertical stepper:
    1. sun.max icon + "Analyzing your lighting..."
    2. paintpalette icon + "Generating color recommendations..."
    3. paintbrush icon + "Creating visualizations..."
    4. doc.text icon + "Assembling your report..."
  - Each step: Circle icon (48pt) + label text
  - Current step: Animated pulsing primary teal icon with spinner
  - Completed step: Filled primary circle with checkmark
  - Future step: Muted gray circle
  - Connecting vertical lines between steps
- "This usually takes 2-5 minutes" caption text
- The view auto-navigates to the report when complete

---

### SCREEN 12: Admin Login

**Simple centered form**:
- Crain logo
- "Admin Access" heading
- Password input (secure field, 48pt height)
- "Login" primary button
- Error message area (red text)
- Biometric auth button if available (Face ID / Touch ID)

---

### SCREEN 13: Admin Dashboard

**NavigationSplitView style** (list -> detail):

**Client List**:
- `.searchable()` search bar at top
- List of client rows:
  - Client name (16pt semibold)
  - Client address (14pt muted)
  - Proposal count badge (right side)
  - Chevron disclosure indicator
- Empty state: "No proposals yet" centered + "Open Visualizer" outline button

**Client Detail** (push destination):
- Client name as nav title
- Address displayed below
- List of proposals:
  - Proposal title (or "Untitled Proposal")
  - Date created (14pt muted)
  - Color count badge
  - Chevron

**Proposal Detail** (push destination):
- 2-column grid of before/after image pairs
- Each pair: Stacked original + result images with color info bar (same as result card)
- Color swatch + name + number per result
- Toolbar: "Print" action, "Delete" action (destructive)

---

## Interaction & Animation Specifications

### Step Transitions
- Fade in + 8pt upward slide, 0.3s ease-out (all wizard step transitions)

### Shimmer Loading
- Gradient animation on skeleton placeholders: Slide from left to right, 1.8s duration, infinite repeat
- Gradient: muted -> primary at 8% opacity -> muted

### Before/After Slider
- Drag gesture controls divider position
- Smooth tracking at 60fps
- Haptic feedback on drag start (light impact)

### Button Press
- Scale down to 0.98 on press, spring animation back

### Color Selection
- Checkmark overlay fades in with 0.2s animation
- Ring appears with 0.2s animation

### Tab Switches
- Standard iOS tab bar animation (cross-fade)

### Navigation
- Standard iOS push/pop transitions (slide from right)
- Sheets slide up from bottom (for modals like Save Proposal)
- Full-screen cover for camera

### Toast Notifications
- Slide down from top, ultra-thin material background, auto-dismiss after 3s
- Swipe up to dismiss

---

## Accessibility Requirements

- All interactive elements minimum 44x44pt tap target
- Color swatches include both visual color AND text label (never color-only information)
- All images have descriptive alt text
- Support Dynamic Type (text should scale with system font size setting)
- VoiceOver labels on all interactive elements
- Sufficient contrast ratios: 4.5:1 for body text, 3:1 for large text
- Before/After slider: accessible via VoiceOver as a slider with percentage value

---

## Deliverables Requested

1. **All 13 screens** listed above at 390x844pt (iPhone 14/15)
2. **Component library sheet** showing all reusable components:
   - Button variants (primary, outline, ghost, CTA gradient)
   - Card styles
   - Input field states (empty, focused, filled, error, validated)
   - Badge/chip styles
   - Color swatch cell (normal, selected, disabled)
   - Step progress indicator states
   - Shimmer/skeleton loading
   - Toast notification
   - Before/After comparison slider
   - Time-of-day swatches
   - Sun timeline visualization
   - Package selection card
   - Mood selection card
3. **Color system** page showing all tokens with swatches
4. **Typography scale** page showing all text styles
5. **Icon set** mapping (SF Symbols used)
6. **Dark mode** variants (stretch goal - not required for v1)

---

## Key Design Principles

1. **Camera-first**: The photo upload step should feel native and fast - this isn't a web uploader, it's an iPhone camera experience
2. **Trust through craft**: Clean, precise, professional design that reflects 70+ years of painting expertise. Not startup-trendy.
3. **Color is the hero**: Paint colors should always be the most visually prominent element on screen. White/neutral chrome lets colors pop.
4. **Progressive disclosure**: Don't overwhelm. Show 3 simple steps up front, reveal complexity only when needed.
5. **iOS-native patterns**: Use standard iOS navigation, tab bars, segmented controls, and gestures. Don't fight the platform.
6. **Thumb-friendly**: Primary actions in bottom third of screen. Sticky action bars for navigation buttons.
