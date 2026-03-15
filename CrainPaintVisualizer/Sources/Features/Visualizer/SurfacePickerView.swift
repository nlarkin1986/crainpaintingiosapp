import SwiftUI

struct SurfacePickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @Environment(VisualizerViewModel.self) private var visualizerVM

    private let presets: [SurfaceType] = [.walls, .trimBase, .accentWall, .doors, .cabinets, .ceiling]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.space16) {
                    WizardHeader(
                        steps: wizardSteps,
                        currentStep: 1,
                        helper: "Choose the surface you want the preview to repaint."
                    )

                    contextStrip

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets, id: \.self) { surface in
                            SurfaceTile(
                                surface: surface,
                                isSelected: visualizerVM.selectedSurface == surface
                            ) {
                                visualizerVM.setSelectedSurface(surface)
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)

                    customSurfaceSection

                    if visualizerVM.selectedSurface == .custom {
                        AppInput(
                            placeholder: "e.g., garage door, fence, brick exterior...",
                            text: Binding(
                                get: { visualizerVM.customSurfaceText },
                                set: { visualizerVM.setCustomSurfaceText($0) }
                            )
                        )
                        .padding(.horizontal, theme.spacingMD)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: visualizerVM.selectedSurface)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)

            FloatingActionBar {
                let isDisabled = visualizerVM.selectedSurface == nil || (visualizerVM.selectedSurface == .custom && visualizerVM.customSurfaceText.isEmpty)
                AppButton("Continue to Colors", variant: .cta, icon: "arrow.right", isDisabled: isDisabled) {
                    router.navigate(to: .itemPicker)
                }
                .accessibilityIdentifier("surfacePicker.visualizeNow")
            }
        }
        .background(theme.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Choose Surface")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var contextStrip: some View {
        AppCard(elevation: .flat) {
            HStack(spacing: theme.space12) {
                Group {
                    if let photo = visualizerVM.photo {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: theme.radiusMD)
                            .fill(theme.secondary)
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))

                VStack(alignment: .leading, spacing: theme.space4) {
                    Text("Your selections")
                        .font(theme.micro.weight(.bold))
                        .tracking(1.0)
                        .textCase(.uppercase)
                        .foregroundStyle(theme.mutedForeground)

                    HStack(spacing: -8) {
                        ForEach(visualizerVM.selectedColors.prefix(4)) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 26, height: 26)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                        }
                    }

                    Text("\(visualizerVM.selectedColors.count) colors ready")
                        .font(theme.caption)
                        .foregroundStyle(theme.foreground)
                }

                Spacer()
            }
            .padding(theme.space16)
        }
        .padding(.horizontal, theme.spacingMD)
    }

    private var customSurfaceSection: some View {
        Button {
            visualizerVM.setSelectedSurface(.custom)
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
            .background(visualizerVM.selectedSurface == .custom ? theme.primary.opacity(0.05) : theme.card)
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
        .padding(.horizontal, theme.spacingMD)
    }

    private var wizardSteps: [String] {
        ["Photo", "Surface", "Colors", "Review"]
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
