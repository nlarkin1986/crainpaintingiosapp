# Design System Cheat Sheet 📋

Quick reference for Crain Paint Visualizer design tokens.

---

## 📐 Spacing Scale

```swift
theme.spacingXS     // 4pt   ••
theme.spacingSM     // 8pt   ••••
theme.spacingMD     // 16pt  ••••••••
theme.spacingLG     // 24pt  ••••••••••••
theme.spacingXL     // 32pt  ••••••••••••••••
theme.spacingXXL    // 48pt  ••••••••••••••••••••••••
```

**When to use:**
- XS → Tiny gaps (icon padding, badge spacing)
- SM → Small gaps (icon + label, chips)
- MD → Default element spacing
- LG → Screen padding, section spacing
- XL → Large section gaps
- XXL → Major visual breaks

---

## 🔤 Typography Scale

### Display (Hero Text)
```swift
TypographyTokens.displayLarge    // 48pt, black   - Landing pages
TypographyTokens.displayMedium   // 40pt, bold    - Page titles
TypographyTokens.displaySmall    // 32pt, bold    - Section heroes
```

### Headings (Sections)
```swift
TypographyTokens.headingLarge    // 28pt, bold      - Main sections
TypographyTokens.headingMedium   // 24pt, bold      - Subsections
TypographyTokens.headingSmall    // 20pt, semibold  - Cards
```

### Body (Content)
```swift
TypographyTokens.bodyLarge       // 18pt, regular  - Large paragraphs
TypographyTokens.body            // 17pt, medium   - Default text
TypographyTokens.bodySmall       // 15pt, regular  - Compact text
```

### Utility (Small Text)
```swift
TypographyTokens.caption         // 14pt, regular   - Descriptions
TypographyTokens.label           // 13pt, semibold  - Form labels
TypographyTokens.micro           // 11pt, bold      - Badges, tags
```

---

## 🎨 Color Tokens

### Brand (Aqua Family)
```swift
ColorTokens.aqua          // #0EA5E9  Primary brand
ColorTokens.aquaDark      // #0C7FB8  Hover/pressed
ColorTokens.aquaLight     // #38B6F0  Highlights
ColorTokens.aquaSubtle    // #D8F3F0  Light backgrounds
```

### Accents
```swift
// Sunshine (Yellow)
ColorTokens.sunshine      // #FBBF24  Primary yellow
ColorTokens.sunshineDark  // #D19719
ColorTokens.sunshineLight // #FCD765
ColorTokens.sunshineSubtle // #FFFAEB

// Sky (Blue)
ColorTokens.sky           // #3B82F6  Primary blue
ColorTokens.skyDark       // #2563EB
ColorTokens.skyLight      // #60A5FA
ColorTokens.skySubtle     // #DDEAF6

// Peach (Orange)
ColorTokens.peach         // #FB923C  Primary orange
ColorTokens.peachDark     // #EA7420
ColorTokens.peachLight    // #FDBA74
ColorTokens.peachSubtle   // #F4E2D7
```

### Text (Ink Family)
```swift
ColorTokens.inkPrimary    // #0F172A  Headings, primary text
ColorTokens.inkSecondary  // #64748B  Body text, descriptions
ColorTokens.inkTertiary   // #94A3B8  Muted text, placeholders
```

### Backgrounds
```swift
ColorTokens.backgroundBase      // #FFFFFF  Pure white
ColorTokens.backgroundSubtle    // #F8FAFC  Off-white screens
ColorTokens.backgroundElevated  // #F1F5F9  Cards, elevated
```

### Borders & Dividers
```swift
ColorTokens.border        // #E2E8F0  Standard borders
ColorTokens.borderSubtle  // #F1F5F9  Very light borders
```

### UI States
```swift
ColorTokens.muted         // #F8FAFC  Muted/disabled
```

### Feedback
```swift
ColorTokens.feedbackSuccess   // #22C55E  Green (success)
ColorTokens.feedbackWarning   // #F59E0B  Orange (warning)
ColorTokens.feedbackError     // #EF4444  Red (error)
ColorTokens.feedbackInfo      // #3B82F6  Blue (info)
```

---

## 🔲 Border Radius

```swift
theme.radiusSM        // 8pt   - Buttons, small chips
theme.radiusMedium    // 10pt  - Medium elements
theme.radiusMD        // 12pt  - Standard cards
theme.radiusLG        // 16pt  - Large cards
theme.radiusXL        // 24pt  - Hero cards, modals
```

---

## 🎯 Common Patterns

### Standard Button
```swift
AppButton("Label", variant: .cta) {
    // Action
}
```

**Variants:**
- `.cta` - Primary call-to-action (aqua)
- `.primary` - Secondary action (white bg)
- `.secondary` - Tertiary action (outlined)
- `.destructive` - Delete/remove (red)
- `.ghost` - Minimal style

### Standard Card
```swift
VStack(alignment: .leading, spacing: theme.spacingMD) {
    // Content
}
.padding(theme.spacingMD)
.background(ColorTokens.backgroundElevated)
.clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
.overlay(
    RoundedRectangle(cornerRadius: theme.radiusLG)
        .stroke(ColorTokens.border, lineWidth: 1)
)
```

### Section Header
```swift
Text("Section Title")
    .font(TypographyTokens.headingMedium)
    .foregroundStyle(ColorTokens.inkPrimary)
    .padding(.horizontal, theme.spacingLG)
    .padding(.bottom, theme.spacingMD)
```

### Body Paragraph
```swift
Text("This is body text with good line spacing.")
    .font(TypographyTokens.body)
    .foregroundStyle(ColorTokens.inkSecondary)
    .lineSpacing(4)
```

### Badge
```swift
Text("NEW")
    .font(TypographyTokens.micro)
    .foregroundStyle(.white)
    .padding(.horizontal, theme.spacingSM)
    .padding(.vertical, theme.spacingXS)
    .background(ColorTokens.aqua)
    .clipShape(Capsule())
```

### Screen Container
```swift
VStack(spacing: theme.spacingLG) {
    // Content
}
.padding(.horizontal, theme.spacingLG)
.padding(.top, theme.spacingMD)
.background(ColorTokens.backgroundBase)
```

---

## 💡 Quick Tips

### Text Hierarchy
```swift
// Page title
.font(TypographyTokens.displayMedium)
.foregroundStyle(ColorTokens.inkPrimary)

// Section title
.font(TypographyTokens.headingMedium)
.foregroundStyle(ColorTokens.inkPrimary)

// Body text
.font(TypographyTokens.body)
.foregroundStyle(ColorTokens.inkSecondary)

// Caption/metadata
.font(TypographyTokens.caption)
.foregroundStyle(ColorTokens.inkTertiary)
```

### Spacing Hierarchy
```swift
VStack(spacing: theme.spacingXL) {        // Major sections
    
    VStack(spacing: theme.spacingLG) {    // Subsections
        
        VStack(spacing: theme.spacingMD) {  // Related items
            
            HStack(spacing: theme.spacingSM) { // Icon + text
                // Elements
            }
        }
    }
}
```

### Color Contrast Rules
```swift
// ✅ Good contrast
Text("Primary")
    .foregroundStyle(ColorTokens.inkPrimary)      // Dark on light ✓
    .background(ColorTokens.backgroundBase)

// ✅ Good contrast
Text("On brand")
    .foregroundStyle(.white)                       // White on dark ✓
    .background(ColorTokens.aqua)

// ❌ Poor contrast
Text("Bad")
    .foregroundStyle(ColorTokens.inkTertiary)     // Light on light ✗
    .background(ColorTokens.backgroundSubtle)
```

---

## 🚀 Copy-Paste Snippets

### Standard Page Layout
```swift
struct MyView: View {
    @Environment(Theme.self) private var theme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacingLG) {
                // Content here
            }
            .padding(.horizontal, theme.spacingLG)
            .padding(.top, theme.spacingMD)
        }
        .background(ColorTokens.backgroundBase)
        .navigationTitle("Page Title")
    }
}
```

### Card with Header
```swift
VStack(alignment: .leading, spacing: theme.spacingMD) {
    Text("Card Title")
        .font(TypographyTokens.headingSmall)
        .foregroundStyle(ColorTokens.inkPrimary)
    
    Text("Card description goes here.")
        .font(TypographyTokens.body)
        .foregroundStyle(ColorTokens.inkSecondary)
    
    AppButton("Action", variant: .primary) {
        // Do something
    }
}
.padding(theme.spacingMD)
.background(ColorTokens.backgroundElevated)
.clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
.overlay(
    RoundedRectangle(cornerRadius: theme.radiusLG)
        .stroke(ColorTokens.border, lineWidth: 1)
)
```

### List Item
```swift
HStack(spacing: theme.spacingMD) {
    // Icon or image
    Circle()
        .fill(ColorTokens.aqua)
        .frame(width: 44, height: 44)
    
    // Content
    VStack(alignment: .leading, spacing: theme.spacingXS) {
        Text("Item Title")
            .font(TypographyTokens.bodySmall.weight(.semibold))
            .foregroundStyle(ColorTokens.inkPrimary)
        
        Text("Item subtitle")
            .font(TypographyTokens.caption)
            .foregroundStyle(ColorTokens.inkSecondary)
    }
    
    Spacer()
    
    // Trailing icon
    Image(systemName: "chevron.right")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(ColorTokens.inkTertiary)
}
.padding(theme.spacingMD)
```

### Empty State
```swift
VStack(spacing: theme.spacingMD) {
    Image(systemName: "tray")
        .font(.system(size: 48, weight: .light))
        .foregroundStyle(ColorTokens.inkTertiary)
    
    Text("No Items Yet")
        .font(TypographyTokens.headingSmall)
        .foregroundStyle(ColorTokens.inkPrimary)
    
    Text("Get started by adding your first item.")
        .font(TypographyTokens.body)
        .foregroundStyle(ColorTokens.inkSecondary)
        .multilineTextAlignment(.center)
    
    AppButton("Add Item", variant: .primary) {
        // Action
    }
}
.padding(theme.spacingXL)
.frame(maxWidth: .infinity)
.background(ColorTokens.backgroundSubtle)
.clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
```

---

## 📱 Screen Size Guidelines

### iPhone SE (Small)
- Use `spacingMD` for screen padding
- Prefer `bodySmall` for dense content
- Stack elements vertically

### iPhone 15 Pro (Standard)
- Use `spacingLG` for screen padding
- Use `body` for all content
- Balance horizontal and vertical layouts

### iPhone 15 Pro Max (Large)
- Use `spacingLG` or `spacingXL` for screen padding
- Can use `bodyLarge` for feature content
- Utilize horizontal space with grids

---

## ✅ Review Checklist

Before committing:
- [ ] No hardcoded spacing numbers
- [ ] No inline `.font()` with sizes
- [ ] No hex color strings
- [ ] Used `AppButton` where appropriate
- [ ] Proper color contrast (WCAG AA)
- [ ] Consistent border radius
- [ ] Tested on small and large screens

---

**Print this out or keep it handy while coding!** 🎨

Last updated: March 6, 2026
