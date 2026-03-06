import SwiftUI

struct SurfacePickerView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @State private var selectedSurface: SurfaceType?
    @State private var customText = ""

    private let presets: [SurfaceType] = [.walls, .trimBase, .accentWall, .doors, .cabinets, .ceiling]
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 2)

                    Text("Where do you want to apply the color?")
                        .font(theme.title)
                        .foregroundStyle(theme.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacingMD)

                    // Surface grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(presets, id: \.self) { surface in
                            SurfaceTile(
                                surface: surface,
                                isSelected: selectedSurface == surface
                            ) {
                                selectedSurface = surface
                                customText = ""
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacingMD)

                    // Custom / Other tile
                    Button {
                        selectedSurface = .custom
                    } label: {
                        HStack(spacing: theme.spacingSM) {
                            Image(systemName: "paintpalette")
                                .font(.system(size: 20))
                            Text("Custom / Other")
                                .font(theme.subhead)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(selectedSurface == .custom ? theme.primary : theme.foreground)
                        .padding(theme.spacingMD)
                        .background(selectedSurface == .custom ? theme.primary.opacity(0.05) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(
                                    selectedSurface == .custom ? theme.primary : theme.border,
                                    style: StrokeStyle(lineWidth: selectedSurface == .custom ? 2 : 1.5, dash: [6])
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, theme.spacingMD)

                    // Custom input
                    if selectedSurface == .custom {
                        AppInput(placeholder: "e.g., garage door, fence, brick exterior...", text: $customText)
                            .padding(.horizontal, theme.spacingMD)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: selectedSurface)
            }

            FloatingActionBar {
                let isDisabled = selectedSurface == nil || (selectedSurface == .custom && customText.isEmpty)
                AppButton("Visualize Now", variant: .cta, icon: "wand.and.stars", isDisabled: isDisabled) {
                    router.navigate(to: .resultsGallery)
                }
            }
        }
        .navigationTitle("Select Surface")
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
                Image(systemName: surface.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? theme.primary : theme.foreground)
                Text(surface.rawValue)
                    .font(theme.subhead)
                    .foregroundStyle(isSelected ? theme.primary : theme.foreground)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? theme.primary.opacity(0.05) : theme.card)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(isSelected ? theme.primary : theme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .contentShape(Rectangle())
        .accessibilityLabel(surface.rawValue)
    }
}
