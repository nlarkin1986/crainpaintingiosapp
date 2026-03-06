import SwiftUI

struct SurfacePickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private let presets: [SurfaceType] = [.walls, .trimBase, .accentWall, .doors, .cabinets, .ceiling]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    BrandedHeader(
                        title: "Select Surface",
                        subtitle: "Where do you want to apply the color?"
                    )

                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 2, icons: ["paintpalette", "camera", "sofa"])

                    // Surface grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets, id: \.self) { surface in
                            SurfaceTile(
                                surface: surface,
                                isSelected: visualizerVM.selectedSurface == surface
                            ) {
                                visualizerVM.selectedSurface = surface
                                visualizerVM.customSurfaceText = ""
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingLG)

                    // Custom / Other tile
                    Button {
                        visualizerVM.selectedSurface = .custom
                    } label: {
                        HStack(spacing: theme.spacingSM) {
                            ZStack {
                                Circle()
                                    .fill(visualizerVM.selectedSurface == .custom ? theme.primary.opacity(0.1) : theme.muted)
                                    .frame(width: 48, height: 48)
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 20))
                                    .foregroundStyle(visualizerVM.selectedSurface == .custom ? theme.primary : theme.mutedForeground)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Custom / Other")
                                    .font(theme.subhead)
                                    .foregroundStyle(visualizerVM.selectedSurface == .custom ? theme.primary : theme.foreground)
                                Text("Describe the surface to paint")
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(theme.mutedForeground)
                        }
                        .padding(theme.spacingMD)
                        .background(visualizerVM.selectedSurface == .custom ? theme.primary.opacity(0.05) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(
                                    visualizerVM.selectedSurface == .custom ? theme.primary : theme.border,
                                    style: StrokeStyle(lineWidth: visualizerVM.selectedSurface == .custom ? 2 : 1.5, dash: [6])
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, theme.spacingLG)

                    // Custom input
                    if visualizerVM.selectedSurface == .custom {
                        AppInput(placeholder: "e.g., garage door, fence, brick exterior...", text: Bindable(visualizerVM).customSurfaceText)
                            .padding(.horizontal, theme.spacingLG)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: visualizerVM.selectedSurface)
            }
            .scrollDismissesKeyboard(.interactively)

            FloatingActionBar {
                let isDisabled = visualizerVM.selectedSurface == nil || (visualizerVM.selectedSurface == .custom && visualizerVM.customSurfaceText.isEmpty)
                AppButton("Visualize Now", variant: .cta, icon: "wand.and.stars", isDisabled: isDisabled) {
                    router.navigate(to: .resultsGallery)
                }
                .accessibilityIdentifier("surfacePicker.visualizeNow")
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SurfaceTile: View {
    @Environment(Theme.self) private var theme
    let surface: SurfaceType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: theme.spacingSM) {
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary.opacity(0.1) : theme.muted)
                        .frame(width: 48, height: 48)
                    Image(systemName: surface.iconName)
                        .font(.system(size: 22))
                        .foregroundStyle(isSelected ? theme.primary : theme.mutedForeground)
                }
                Text(surface.rawValue)
                    .font(theme.subhead)
                    .foregroundStyle(isSelected ? theme.primary : theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? theme.primary.opacity(0.05) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .contentShape(Rectangle())
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityLabel(surface.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Double tap to select this surface")
        .accessibilityIdentifier("surfacePicker.surface.\(surface.testIdentifier)")
    }
}
