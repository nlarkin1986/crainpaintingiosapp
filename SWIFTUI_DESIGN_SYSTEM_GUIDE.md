# Translating Tailwind/shadcn Web Design System to Native SwiftUI

## Research Summary

This guide maps your web application's Tailwind CSS + shadcn/ui design system to idiomatic
SwiftUI patterns for a native iOS app. Each section covers a specific area: design tokens,
typography, components, and complex UI patterns.

---

## 1. Design Tokens: CSS Variables to SwiftUI Color System

### Web (CSS Variables)
Your web app uses CSS custom properties like `--background`, `--foreground`, `--primary`,
`--accent`, `--muted`, `--destructive`, `--card`, `--border`.

### SwiftUI Equivalent: Asset Catalog + Color Extensions

**Recommended approach: Xcode Asset Catalog with semantic naming.**

1. Create a Color Set in `Assets.xcassets` for each token (`Background`, `Foreground`,
   `Primary`, `Accent`, `Muted`, `Destructive`, `CardBackground`, `Border`).
2. Each Color Set has "Any Appearance" and "Dark" variants, giving you automatic light/dark
   mode support -- the iOS equivalent of CSS `prefers-color-scheme`.

Then create a typed `Color` extension:

```swift
// Theme/AppColors.swift
import SwiftUI

extension Color {
    static let appBackground   = Color("Background")
    static let appForeground   = Color("Foreground")
    static let appPrimary      = Color("Primary")
    static let appAccent       = Color("Accent")
    static let appMuted        = Color("Muted")
    static let appDestructive  = Color("Destructive")
    static let appCard         = Color("CardBackground")
    static let appBorder       = Color("Border")
}
```

**Advanced approach: Dynamic color initializer (no asset catalog needed)**

```swift
extension Color {
    init(light: Color, dark: Color) {
        self.init(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

    static let appPrimary = Color(
        light: Color(hex: "#1a365d"),
        dark:  Color(hex: "#90cdf4")
    )
}
```

**Design token struct (closest to CSS variables pattern):**

```swift
struct DesignTokens {
    struct Colors {
        static let background  = Color.appBackground
        static let foreground  = Color.appForeground
        static let primary     = Color.appPrimary
        static let accent      = Color.appAccent
        static let muted       = Color.appMuted
        static let destructive = Color.appDestructive
        static let card        = Color.appCard
        static let border      = Color.appBorder
    }

    struct Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
    }

    struct CornerRadius {
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16  // rounded-xl equivalent
        static let full: CGFloat = 9999
    }
}
```

---

## 2. Typography: Open Sans + Merriweather Sans

### Setup Steps

1. **Add font files** (.ttf or .otf) to your Xcode project target.
2. **Register in Info.plist** under "Fonts provided by application":
   ```
   - OpenSans-Regular.ttf
   - OpenSans-SemiBold.ttf
   - OpenSans-Bold.ttf
   - MerriweatherSans-Bold.ttf
   - MerriweatherSans-SemiBold.ttf
   ```
3. **Create a typed Font extension:**

```swift
// Theme/AppFonts.swift
import SwiftUI

extension Font {
    // Body font: Open Sans
    static func body(_ size: CGFloat = 16, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .semibold: return .custom("OpenSans-SemiBold", size: size)
        case .bold:     return .custom("OpenSans-Bold", size: size)
        default:        return .custom("OpenSans-Regular", size: size)
        }
    }

    // Heading font: Merriweather Sans
    static func heading(_ size: CGFloat = 24, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .semibold: return .custom("MerriweatherSans-SemiBold", size: size)
        default:        return .custom("MerriweatherSans-Bold", size: size)
        }
    }
}

// Usage:
// Text("Welcome").font(.heading(28))
// Text("Description").font(.body(16, weight: .semibold))
```

**Important:** The font name passed to `.custom()` must be the PostScript name, not the
filename. Print all registered fonts to verify:

```swift
UIFont.familyNames.sorted().forEach { family in
    UIFont.fontNames(forFamilyName: family).forEach { print($0) }
}
```

---

## 3. Component Mapping: shadcn to SwiftUI

### 3.1 Button (variants: default, outline, ghost, cta)

```swift
enum ButtonVariant {
    case `default`, outline, ghost, cta
}

struct AppButton: View {
    let title: String
    let variant: ButtonVariant
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body(16, weight: .semibold))
                .frame(maxWidth: variant == .cta ? .infinity : nil)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .foregroundColor(foregroundColor)
                .background(backgroundColor)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(borderColor, lineWidth: variant == .outline ? 1.5 : 0)
                )
        }
        .buttonStyle(.plain)
    }

    private var foregroundColor: Color {
        switch variant {
        case .default: return .white
        case .outline: return .appPrimary
        case .ghost:   return .appForeground
        case .cta:     return .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .default: return .appPrimary
        case .outline: return .clear
        case .ghost:   return .clear
        case .cta:     return .appAccent
        }
    }

    private var borderColor: Color {
        variant == .outline ? .appBorder : .clear
    }
}
```

### 3.2 Card (rounded-xl, border, bg-card)

```swift
struct AppCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.card)
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Usage:
// AppCard {
//     VStack(alignment: .leading) {
//         Text("Title").font(.heading(20))
//         Text("Body text").font(.body())
//     }
// }
```

### 3.3 Badge (variant: outline)

```swift
struct AppBadge: View {
    let text: String
    var variant: BadgeVariant = .outline

    enum BadgeVariant { case filled, outline }

    var body: some View {
        Text(text)
            .font(.body(12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(variant == .outline ? .appPrimary : .white)
            .background(variant == .outline ? Color.clear : .appPrimary)
            .cornerRadius(DesignTokens.CornerRadius.full)
            .overlay(
                Capsule()
                    .stroke(Color.appPrimary, lineWidth: variant == .outline ? 1 : 0)
            )
    }
}
```

### 3.4 Input (h-12, rounded, text-base)

```swift
struct AppTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.body(16))
            .padding(.horizontal, 16)
            .frame(height: 48)  // h-12 = 48pt
            .background(DesignTokens.Colors.background)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
    }
}
```

### 3.5 Skeleton (loading placeholders)

SwiftUI has a built-in `.redacted(reason: .placeholder)` modifier that replaces content
with grey blocks. Combine it with a shimmer animation for the Skeleton effect:

```swift
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.4), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(20))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }

    func skeleton(isLoading: Bool) -> some View {
        redacted(reason: isLoading ? .placeholder : [])
            .shimmer()
            .disabled(isLoading)
    }
}

// Usage:
// CardView(item: placeholder)
//     .skeleton(isLoading: viewModel.isLoading)
```

Also see the `SwiftUI-Shimmer` package by markiv for a production-ready solution.

### 3.6 Toast/Snackbar (Sonner equivalent)

There is no native iOS toast. The best approaches are:

**Option A: Custom overlay (recommended -- closest to Sonner)**

```swift
struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let type: ToastType

    enum ToastType {
        case success, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error:   return "xmark.circle.fill"
            case .info:    return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return .green
            case .error:   return .appDestructive
            case .info:    return .appPrimary
            }
        }
    }

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content

            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: type.icon)
                        .foregroundColor(type.color)
                    Text(message)
                        .font(.body(14, weight: .semibold))
                        .foregroundColor(.appForeground)
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { isShowing = false }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            if value.translation.height < -20 {
                                withAnimation { isShowing = false }
                            }
                        }
                )
            }
        }
        .animation(.spring(response: 0.4), value: isShowing)
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String,
               type: ToastModifier.ToastType = .info) -> some View {
        modifier(ToastModifier(isShowing: isShowing, message: message, type: type))
    }
}
```

**Option B: Use `.sensoryFeedback()` (iOS 17+) alongside the toast for haptic confirmation.**

---

## 4. Complex UI Patterns

### 4.1 Step Progress Indicator (3-step wizard with dots)

```swift
struct StepProgressIndicator: View {
    let totalSteps: Int
    let currentStep: Int
    let labels: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<totalSteps, id: \.self) { index in
                VStack(spacing: 8) {
                    // Dot
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.appPrimary : Color.appMuted)
                            .frame(width: 32, height: 32)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.body(14, weight: .semibold))
                                .foregroundColor(index == currentStep ? .white : .appForeground)
                        }
                    }

                    // Label
                    Text(labels[index])
                        .font(.body(12))
                        .foregroundColor(index <= currentStep ? .appPrimary : .appMuted)
                }

                // Connector line
                if index < totalSteps - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.appPrimary : Color.appMuted)
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 24)
                }
            }
        }
        .padding(.horizontal)
    }
}
```

### 4.2 Color Swatch Grid (LazyVGrid)

```swift
struct ColorSwatch: Identifiable {
    let id = UUID()
    let name: String
    let number: String
    let color: Color
}

struct ColorSwatchGrid: View {
    let swatches: [ColorSwatch]
    @Binding var selectedSwatch: ColorSwatch?

    // 2-3 columns adaptive based on screen width
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(swatches) { swatch in
                Button {
                    selectedSwatch = swatch
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(swatch.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(Color.appBorder, lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(swatch.name)
                                .font(.body(14, weight: .semibold))
                                .foregroundColor(.appForeground)
                            Text(swatch.number)
                                .font(.body(12))
                                .foregroundColor(.appMuted)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.appCard)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(
                                selectedSwatch?.id == swatch.id
                                    ? Color.appPrimary
                                    : Color.appBorder,
                                lineWidth: selectedSwatch?.id == swatch.id ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 4.3 Before/After Image Comparison Slider

This is the SwiftUI equivalent of `react-compare-slider`:

```swift
struct BeforeAfterSlider: View {
    let beforeImage: Image
    let afterImage: Image
    @State private var sliderPosition: CGFloat = 0.5

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Before image (full width, underneath)
                beforeImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // After image (masked by slider position)
                afterImage
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: geometry.size.width * sliderPosition)
                            Spacer(minLength: 0)
                        }
                    )

                // Divider line + handle
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: geometry.size.width * sliderPosition - 1)

                    Rectangle()
                        .fill(.white)
                        .frame(width: 2)
                        .shadow(radius: 2)

                    Spacer(minLength: 0)
                }

                // Drag handle circle
                Circle()
                    .fill(.white)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .overlay(
                        HStack(spacing: 2) {
                            Image(systemName: "chevron.left")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    )
                    .position(
                        x: geometry.size.width * sliderPosition,
                        y: geometry.size.height / 2
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPosition = value.location.x / geometry.size.width
                                sliderPosition = min(max(newPosition, 0.01), 0.99)
                            }
                    )

                // Labels
                VStack {
                    HStack {
                        Text("BEFORE")
                            .font(.body(11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(12)
                        Spacer()
                        Text("AFTER")
                            .font(.body(11, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .padding(12)
                    }
                    Spacer()
                }
            }
        }
        .cornerRadius(DesignTokens.CornerRadius.lg)
    }
}
```

**Third-party option:** `MoSlider` (iOS 17+) provides a production-ready component with
RTL support, accessibility, and animation built in.

### 4.4 Camera Capture + Photo Picker

SwiftUI's native `PhotosPicker` (iOS 16+) handles gallery selection but not camera capture.
You need a UIKit bridge for camera:

```swift
import SwiftUI
import PhotosUI

// MARK: - Gallery Picker (native SwiftUI)
struct PhotoUploadView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var showCamera = false

    var body: some View {
        VStack(spacing: 16) {
            // Camera button
            Button {
                showCamera = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Take Photo")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appPrimary)
                .foregroundColor(.white)
                .cornerRadius(DesignTokens.CornerRadius.md)
            }

            // Gallery picker
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .images
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                    Text("Choose from Library")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.appCard)
                .foregroundColor(.appPrimary)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
            }
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            selectedImages.append(image)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: Binding(
                get: { nil },
                set: { if let img = $0 { selectedImages.append(img) } }
            ))
            .ignoresSafeArea()
        }
    }
}

// MARK: - Camera UIKit Bridge
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

### 4.5 Multi-Step Wizard with FlowRouter

```swift
// MARK: - Flow Router (NavigationPath-based)
enum WizardStep: Hashable {
    case selectRoom
    case selectMood
    case uploadPhoto
    case selectSurface
    case results
}

@Observable
class WizardRouter {
    var path = NavigationPath()
    var currentStepIndex: Int = 0

    // Flow state -- lives here, NOT in individual step views
    var selectedRoomType: String?
    var selectedMood: String?
    var uploadedImage: UIImage?
    var selectedSurface: String?

    func advance(to step: WizardStep) {
        path.append(step)
        currentStepIndex += 1
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
            currentStepIndex = max(0, currentStepIndex - 1)
        }
    }

    func reset() {
        path = NavigationPath()
        currentStepIndex = 0
        selectedRoomType = nil
        selectedMood = nil
        uploadedImage = nil
        selectedSurface = nil
    }
}

// MARK: - Wizard Host View
struct WizardView: View {
    @State private var router = WizardRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            // Step 1: Room Selection
            RoomSelectionView()
                .navigationDestination(for: WizardStep.self) { step in
                    switch step {
                    case .selectMood:    MoodSelectionView()
                    case .uploadPhoto:   PhotoUploadStepView()
                    case .selectSurface: SurfacePickerView()
                    case .results:       ResultsView()
                    default: EmptyView()
                    }
                }
        }
        .environment(router)
    }
}
```

### 4.6 Sticky Bottom Action Bar

Two approaches:

**Option A: `.safeAreaInset(edge: .bottom)` -- Recommended**

This pushes content up and stays fixed at the bottom, even with scrollable content:

```swift
struct StepView: View {
    @Environment(WizardRouter.self) var router

    var body: some View {
        ScrollView {
            // Main content here
            VStack(spacing: 16) {
                // ...
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    AppButton(title: "Back", variant: .outline) {
                        router.goBack()
                    }
                    AppButton(title: "Continue", variant: .cta) {
                        router.advance(to: .selectMood)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
    }
}
```

**Option B: `.toolbar(content:)` with `.bottomBar` placement**

```swift
.toolbar {
    ToolbarItemGroup(placement: .bottomBar) {
        Button("Back") { router.goBack() }
        Spacer()
        Button("Continue") { router.advance(to: .selectMood) }
            .buttonStyle(.borderedProminent)
    }
}
```

The `.safeAreaInset` approach gives you full control over styling and is preferred for
custom designs. The `.toolbar` approach is simpler but limited to system styling.

### 4.7 Surface Picker (Grid of Selectable Buttons)

```swift
struct SurfacePickerView: View {
    let surfaces = ["Walls", "Ceiling", "Trim", "Doors", "Cabinets", "Exterior"]
    @State private var selected: Set<String> = []

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(surfaces, id: \.self) { surface in
                Button {
                    if selected.contains(surface) {
                        selected.remove(surface)
                    } else {
                        selected.insert(surface)
                    }
                } label: {
                    Text(surface)
                        .font(.body(14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(
                            selected.contains(surface) ? .white : .appForeground
                        )
                        .background(
                            selected.contains(surface) ? Color.appPrimary : Color.appCard
                        )
                        .cornerRadius(DesignTokens.CornerRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                .stroke(
                                    selected.contains(surface)
                                        ? Color.appPrimary
                                        : Color.appBorder,
                                    lineWidth: 1.5
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 4.8 Package Selection Cards with "Most Popular" Badge

```swift
struct Package: Identifiable {
    let id = UUID()
    let name: String
    let price: String
    let features: [String]
    let isMostPopular: Bool
}

struct PackageSelectionView: View {
    let packages: [Package]
    @Binding var selectedPackage: Package?

    var body: some View {
        VStack(spacing: 16) {
            ForEach(packages) { package in
                Button {
                    selectedPackage = package
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(package.name)
                                .font(.heading(20))
                                .foregroundColor(.appForeground)
                            Spacer()
                            if package.isMostPopular {
                                AppBadge(text: "Most Popular", variant: .outline)
                            }
                        }

                        Text(package.price)
                            .font(.heading(28, weight: .bold))
                            .foregroundColor(.appPrimary)

                        ForEach(package.features, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.appAccent)
                                    .font(.system(size: 16))
                                Text(feature)
                                    .font(.body(14))
                                    .foregroundColor(.appForeground)
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(Color.appCard)
                    .cornerRadius(DesignTokens.CornerRadius.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                            .stroke(
                                selectedPackage?.id == package.id
                                    ? Color.appPrimary
                                    : Color.appBorder,
                                lineWidth: selectedPackage?.id == package.id ? 2 : 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 4.9 Quiz Flow (Room Type Cards, Mood Cards, Color Suggestion Cards)

```swift
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .padding(DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.appPrimary.opacity(0.1) : Color.appCard)
                .cornerRadius(DesignTokens.CornerRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                        .stroke(
                            isSelected ? Color.appPrimary : Color.appBorder,
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// Room type card usage:
struct RoomTypeCard: View {
    let icon: String      // SF Symbol name
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectableCard(isSelected: isSelected, action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .appPrimary : .appMuted)
                Text(title)
                    .font(.body(14, weight: .semibold))
                    .foregroundColor(.appForeground)
            }
            .padding(.vertical, 8)
        }
    }
}

// Mood card with color gradient:
struct MoodCard: View {
    let mood: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectableCard(isSelected: isSelected, action: action) {
            VStack(spacing: 12) {
                LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
                    .frame(height: 60)
                    .cornerRadius(8)
                Text(mood)
                    .font(.body(14, weight: .semibold))
                    .foregroundColor(.appForeground)
            }
        }
    }
}
```

### 4.10 Save Proposal Modal with Client Search

```swift
struct SaveProposalSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedClient: Client?
    @State private var proposalName = ""

    let clients: [Client]
    let onSave: (String, Client?) -> Void

    var filteredClients: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                AppTextField(placeholder: "Proposal name", text: $proposalName)
                    .padding(.horizontal)

                // Client search
                VStack(alignment: .leading, spacing: 8) {
                    Text("Assign to Client")
                        .font(.body(14, weight: .semibold))
                        .padding(.horizontal)

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.appMuted)
                        TextField("Search clients...", text: $searchText)
                            .font(.body(16))
                    }
                    .padding(12)
                    .background(Color.appCard)
                    .cornerRadius(DesignTokens.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                            .stroke(Color.appBorder, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                List(filteredClients) { client in
                    Button {
                        selectedClient = client
                        searchText = client.name
                    } label: {
                        HStack {
                            Text(client.name)
                                .foregroundColor(.appForeground)
                            Spacer()
                            if selectedClient?.id == client.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.appPrimary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Save Proposal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(proposalName, selectedClient)
                        dismiss()
                    }
                    .disabled(proposalName.isEmpty)
                }
            }
        }
    }
}
```

### 4.11 Admin Dashboard with Client List, Search, Proposal Details

```swift
struct AdminDashboardView: View {
    @State private var searchText = ""
    @State private var selectedClient: Client?
    @State private var clients: [Client] = []

    var filteredClients: [Client] {
        if searchText.isEmpty { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            // Master: Client list
            List(filteredClients, selection: $selectedClient) { client in
                NavigationLink(value: client) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.body(16, weight: .semibold))
                        Text("\(client.proposalCount) proposals")
                            .font(.body(13))
                            .foregroundColor(.appMuted)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search clients")
            .navigationTitle("Clients")
        } detail: {
            // Detail: Proposal list and details
            if let client = selectedClient {
                ClientDetailView(client: client)
            } else {
                ContentUnavailableView(
                    "Select a Client",
                    systemImage: "person.crop.circle",
                    description: Text("Choose a client to view their proposals")
                )
            }
        }
    }
}
```

On iPhone, `NavigationSplitView` automatically collapses to a push-based stack.

---

## 5. Component Mapping Quick Reference

| Web (shadcn/Tailwind)         | SwiftUI Native Equivalent                          |
|-------------------------------|-----------------------------------------------------|
| `<Button variant="default">`  | Custom `AppButton` with `ButtonStyle`               |
| `<Card>`                      | Custom `AppCard` ViewBuilder container               |
| `<Badge variant="outline">`   | Custom `AppBadge` with `Capsule` overlay            |
| `<Input>`                     | `TextField` with custom frame + border styling       |
| `<Skeleton>`                  | `.redacted(reason: .placeholder)` + shimmer modifier |
| `<Sonner>` (toast)            | Custom `ToastModifier` overlay with animation        |
| `rounded-xl`                  | `.cornerRadius(16)` or `RoundedRectangle(cornerRadius: 16)` |
| `bg-card`                     | `.background(Color.appCard)`                        |
| `border`                      | `.overlay(RoundedRectangle(...).stroke(...))`         |
| `text-base`                   | `.font(.body(16))`                                  |
| `h-12`                        | `.frame(height: 48)`                                |
| CSS variables `--primary`     | Asset catalog Color Sets + `Color` extension         |
| `grid-cols-2`                 | `LazyVGrid(columns: [GridItem(.flexible()), ...])`  |
| `sticky bottom-0`            | `.safeAreaInset(edge: .bottom)`                      |
| `react-compare-slider`        | Custom `BeforeAfterSlider` with mask + DragGesture   |
| `next/navigation` routing     | `NavigationStack` + `NavigationPath` FlowRouter      |
| `Dialog` / `Sheet`            | `.sheet()` or `.fullScreenCover()`                   |
| `prefers-color-scheme`        | Automatic via Asset Catalog light/dark variants       |
| Framer Motion animations      | `withAnimation(.spring())` + `.transition()`         |

---

## 6. Libraries Worth Considering

| Library           | Purpose                           | Notes                             |
|-------------------|-----------------------------------|-----------------------------------|
| `swiftcn-ui`      | shadcn-inspired SwiftUI components | Button, Card, Badge, Input, etc. Currently seeking maintainer. |
| `SwiftUI-Shimmer` | Shimmer loading effect            | Drop-in `.shimmering()` modifier  |
| `MoSlider`        | Before/after comparison           | iOS 17+, RTL support, accessible  |
| `StepperView`     | Step indicator component          | Horizontal/vertical, customizable |
| `Steps`           | Wizard step component             | Lightweight wizard stepper         |

---

## 7. Key Architectural Recommendations

### Design System File Structure

```
App/
  Theme/
    DesignTokens.swift        // Colors, spacing, radii, shadows
    AppColors.swift            // Color extensions
    AppFonts.swift             // Font extensions
  Components/
    AppButton.swift
    AppCard.swift
    AppBadge.swift
    AppTextField.swift
    SelectableCard.swift
    StepProgressIndicator.swift
    BeforeAfterSlider.swift
    ToastModifier.swift
    ShimmerModifier.swift
  Features/
    Wizard/
      WizardRouter.swift
      WizardView.swift
      Steps/
        RoomSelectionView.swift
        MoodSelectionView.swift
        PhotoUploadStepView.swift
        SurfacePickerView.swift
        ResultsView.swift
    Admin/
      AdminDashboardView.swift
      ClientDetailView.swift
    Quiz/
      QuizFlowView.swift
```

### State Management

- Use `@Observable` (iOS 17+) for the `WizardRouter` and shared state
- Keep navigation state (`NavigationPath`) separate from form data
- Store form data in the router or a dedicated `FormState` object, not in `@State` on
  individual views (those reset when SwiftUI recreates the view)
- Use `.environment()` to inject the router into the view hierarchy

### Navigation Rules

- **Push** for main wizard flow steps (NavigationStack)
- **Sheet** for save dialogs, client search, minor tasks
- **FullScreenCover** for camera capture (separate "world")
- **Never** nest NavigationStacks
- **Never** put main flow screens in sheets (users can swipe-dismiss and lose context)

### Performance

- `LazyVGrid` / `LazyHGrid` for color swatches and card grids (views created on demand)
- Use `.task {}` for async image loading
- Cache loaded images in a shared image cache, not in view state
