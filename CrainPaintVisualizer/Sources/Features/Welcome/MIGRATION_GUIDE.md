# Design Token Migration Guide

## Quick Reference for Migrating Views to New Design System

This guide helps you quickly migrate any remaining views to use the new design tokens.

---

## 🔄 Three-Step Migration Process

### Step 1: Import and Environment
```swift
import SwiftUI

struct MyView: View {
    @Environment(Theme.self) private var theme  // ✅ Required
    
    var body: some View {
        // Your view content
    }
}
```

### Step 2: Replace Spacing
Find and replace all spacing references:

| Old | New |
|-----|-----|
| `theme.space4` | `theme.spacingXS` |
| `theme.space8` | `theme.spacingSM` |
| `theme.space12` | `theme.spacingMD` (12pt deprecated, use 16) |
| `theme.space16` | `theme.spacingMD` |
| `theme.space20` | `theme.spacingLG` (20pt deprecated, use 24) |
| `theme.space24` | `theme.spacingLG` |
| `theme.space32` | `theme.spacingXL` |
| `theme.space40` | `theme.spacingXXL` (40pt deprecated, use 48) |

### Step 3: Replace Typography and Colors
See detailed tables below.

---

## 📐 Spacing Token Reference

### Complete Spacing Scale
```swift
theme.spacingXS     // 4pt  - Tight internal spacing
theme.spacingSM     // 8pt  - Small gaps, icon spacing
theme.spacingMD     // 16pt - Default between elements
theme.spacingLG     // 24pt - Section spacing
theme.spacingXL     // 32pt - Large section gaps
theme.spacingXXL    // 48pt - Major section dividers
```

### Common Use Cases
```swift
// Card internal padding
.padding(theme.spacingMD)

// Vertical stack spacing
VStack(spacing: theme.spacingLG) { }

// Screen edge padding
.padding(.horizontal, theme.spacingLG)

// Icon and text spacing
HStack(spacing: theme.spacingSM) { }
```

---

## 🔤 Typography Migration

### Display Text (Large Headlines)
```swift
// OLD
.font(.system(size: 48, weight: .black))
.font(.system(size: 40, weight: .bold))
.font(.system(size: 32, weight: .bold))

// NEW
.font(TypographyTokens.displayLarge)   // 48pt, black
.font(TypographyTokens.displayMedium)  // 40pt, bold
.font(TypographyTokens.displaySmall)   // 32pt, bold
```

### Headings (Section Titles)
```swift
// OLD
.font(.system(size: 28, weight: .bold))
.font(.system(size: 24, weight: .bold))
.font(.system(size: 20, weight: .semibold))

// NEW
.font(TypographyTokens.headingLarge)   // 28pt, bold
.font(TypographyTokens.headingMedium)  // 24pt, bold
.font(TypographyTokens.headingSmall)   // 20pt, semibold
```

### Body Text (Paragraphs)
```swift
// OLD
.font(.system(size: 18, weight: .regular))
.font(.system(size: 17, weight: .medium))
.font(.system(size: 15, weight: .regular))

// NEW
.font(TypographyTokens.bodyLarge)      // 18pt, regular
.font(TypographyTokens.body)           // 17pt, medium
.font(TypographyTokens.bodySmall)      // 15pt, regular
```

### Small Text (Captions, Labels)
```swift
// OLD
.font(.system(size: 14, weight: .regular))
.font(.system(size: 13, weight: .semibold))
.font(.system(size: 12, weight: .regular))
.font(.system(size: 11, weight: .bold))

// NEW
.font(TypographyTokens.caption)        // 14pt, regular
.font(TypographyTokens.label)          // 13pt, semibold
.font(TypographyTokens.micro)          // 11pt, bold
```

### Font Weight Modifiers
```swift
// Can be combined with any typography token
.font(TypographyTokens.body.weight(.semibold))
.font(TypographyTokens.caption.weight(.bold))
.font(TypographyTokens.label.weight(.medium))
```

---

## 🎨 Color Migration

### Text Colors
```swift
// OLD
.foregroundStyle(Color(hex: "0F172A"))  // Dark text
.foregroundStyle(Color(hex: "64748B"))  // Medium text
.foregroundStyle(Color(hex: "94A3B8"))  // Light text
.foregroundStyle(Color.primary)

// NEW
.foregroundStyle(ColorTokens.inkPrimary)    // Primary text
.foregroundStyle(ColorTokens.inkSecondary)  // Secondary text
.foregroundStyle(ColorTokens.inkTertiary)   // Tertiary text
.foregroundStyle(ColorTokens.inkPrimary)    // Use instead of .primary
```

### Brand Colors
```swift
// OLD
.foregroundStyle(theme.primary)
.background(Color(hex: "0EA5E9"))
.tint(.blue)

// NEW
.foregroundStyle(ColorTokens.aqua)       // Primary brand
.background(ColorTokens.aquaDark)        // Dark variant
.foregroundStyle(ColorTokens.aquaLight)  // Light variant
.background(ColorTokens.aquaSubtle)      // Very light background
```

### Accent Colors
```swift
// NEW - Sunshine (Yellow)
ColorTokens.sunshine
ColorTokens.sunshineDark
ColorTokens.sunshineLight
ColorTokens.sunshineSubtle

// NEW - Sky (Blue)
ColorTokens.sky
ColorTokens.skyDark
ColorTokens.skyLight
ColorTokens.skySubtle

// NEW - Peach (Orange)
ColorTokens.peach
ColorTokens.peachDark
ColorTokens.peachLight
ColorTokens.peachSubtle
```

### Background Colors
```swift
// OLD
.background(.white)
.background(Color(hex: "F8FAFC"))
.background(Color(hex: "F1F5F9"))

// NEW
.background(ColorTokens.backgroundBase)     // Pure white
.background(ColorTokens.backgroundSubtle)   // Off-white
.background(ColorTokens.backgroundElevated) // Cards, elevated
```

### Border Colors
```swift
// OLD
.stroke(Color.gray.opacity(0.2))
.stroke(Color(hex: "E2E8F0"))
.border(Color.secondary)

// NEW
.stroke(ColorTokens.border)         // Standard borders
.stroke(ColorTokens.borderSubtle)   // Very light borders
```

### UI State Colors
```swift
// OLD
.background(Color.gray.opacity(0.1))
.background(.ultraThinMaterial)

// NEW
.background(ColorTokens.muted)            // Muted backgrounds
.background(ColorTokens.backgroundSubtle) // Subtle bg
```

### Feedback Colors
```swift
// OLD
.foregroundStyle(.green)
.foregroundStyle(.red)
.foregroundStyle(.orange)
.foregroundStyle(.blue)

// NEW
.foregroundStyle(ColorTokens.feedbackSuccess)  // Green
.foregroundStyle(ColorTokens.feedbackError)    // Red
.foregroundStyle(ColorTokens.feedbackWarning)  // Orange
.foregroundStyle(ColorTokens.feedbackInfo)     // Blue
```

---

## 🔲 Radius Migration

```swift
// OLD
.cornerRadius(8)
.cornerRadius(12)
.cornerRadius(16)
.cornerRadius(24)

// NEW
.clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))   // 8pt
.clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))   // 12pt
.clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))   // 16pt
.clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))   // 24pt

// Also available
theme.radiusMedium  // 10pt (between SM and MD)
```

---

## 🎯 Complete Migration Example

### Before
```swift
struct OldView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color(hex: "0F172A"))
                .padding(.bottom, 16)
            
            Text("Get started today")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color(hex: "64748B"))
                .padding(.horizontal, 20)
            
            Button("Continue") {
                // Action
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .padding(.top, 32)
        .background(Color(hex: "F8FAFC"))
    }
}
```

### After
```swift
struct NewView: View {
    @Environment(Theme.self) private var theme
    
    var body: some View {
        VStack(spacing: theme.spacingLG) {
            Text("Welcome")
                .font(TypographyTokens.displaySmall)
                .foregroundStyle(ColorTokens.inkPrimary)
                .padding(.bottom, theme.spacingMD)
            
            Text("Get started today")
                .font(TypographyTokens.body)
                .foregroundStyle(ColorTokens.inkSecondary)
                .padding(.horizontal, theme.spacingLG)
            
            AppButton("Continue", variant: .cta) {
                // Action
            }
            .padding(.horizontal, theme.spacingLG)
        }
        .padding(.top, theme.spacingXL)
        .background(ColorTokens.backgroundSubtle)
    }
}
```

---

## ✅ Migration Checklist

For each view you migrate:

- [ ] Add `@Environment(Theme.self) private var theme`
- [ ] Replace all `space*` with `spacing*` tokens
- [ ] Replace all inline `.font()` with `TypographyTokens.*`
- [ ] Replace all hex colors with `ColorTokens.*`
- [ ] Replace `theme.primary` with `ColorTokens.aqua`
- [ ] Replace `.cornerRadius()` with `.clipShape(RoundedRectangle(...))`
- [ ] Consider using `AppButton` instead of custom buttons
- [ ] Consider using `AppCard` for card layouts
- [ ] Test on multiple screen sizes
- [ ] Verify dark mode (if applicable)

---

## 🛠 Find & Replace Shortcuts

### VS Code / Xcode Find & Replace

**Spacing (use Find as regex):**
```regex
Find: theme\.space(\d+)
Replace: theme.spacing[LOOKUP_TABLE]
```

Manual lookup needed:
- `space4` → `spacingXS`
- `space8` → `spacingSM`
- `space16` → `spacingMD`
- `space24` → `spacingLG`
- `space32` → `spacingXL`

**Colors (exact match):**
```
Find: Color(hex: "0F172A")
Replace: ColorTokens.inkPrimary

Find: Color(hex: "64748B")
Replace: ColorTokens.inkSecondary

Find: Color(hex: "F8FAFC")
Replace: ColorTokens.backgroundSubtle

Find: theme.primary
Replace: ColorTokens.aqua
```

---

## 📚 Additional Resources

- **ColorTokens.swift** - Complete color palette
- **TypographyTokens.swift** - All typography scales
- **AppButton.swift** - Standard button component
- **AppCard.swift** - Standard card component
- **IMPLEMENTATION_COMPLETE.md** - Implementation summary
- **DesignSystemGuide.md** - Full design system docs

---

## 💡 Pro Tips

### 1. Use Components Over Custom Views
```swift
// ❌ Don't rebuild buttons
Button("Action") { }
    .font(.system(size: 16, weight: .semibold))
    .foregroundStyle(.white)
    .frame(height: 48)
    .background(.blue)
    .cornerRadius(12)

// ✅ Use AppButton
AppButton("Action", variant: .cta) { }
```

### 2. Group Related Spacing
```swift
// ❌ Don't mix spacing scales
VStack(spacing: 14) { }  // Random number

// ✅ Use semantic tokens
VStack(spacing: theme.spacingMD) { }  // Clear intention
```

### 3. Use Semantic Colors
```swift
// ❌ Don't use generic colors
.foregroundStyle(.gray)

// ✅ Use semantic tokens
.foregroundStyle(ColorTokens.inkSecondary)  // Shows purpose
```

### 4. Combine Typography with Modifiers
```swift
// ✅ Start with token, then modify
.font(TypographyTokens.body.weight(.bold))
.font(TypographyTokens.caption.weight(.semibold))
```

---

## 🎉 You're Done!

Once you've migrated a view:
1. Test it visually
2. Check different screen sizes
3. Verify spacing and typography look correct
4. Commit with a clear message: `"Migrate [ViewName] to new design tokens"`

Happy coding! 🚀
