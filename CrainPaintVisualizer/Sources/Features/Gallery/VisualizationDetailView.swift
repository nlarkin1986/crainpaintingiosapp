import SwiftUI

struct VisualizationDetailView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    let visualizationId: String

    @State private var showBeforeAfter = true

    // Mock data — will be fetched by ID in production
    private var visualization: Visualization {
        Visualization(
            id: visualizationId,
            colorName: "Hale Navy",
            colorHex: "3C4659",
            colorCode: "HC-154",
            roomName: "Living Room",
            beforeImageName: "room1",
            afterImageName: "room1_after",
            surface: "Accent Wall"
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    // View mode toggle
                    Picker("View Mode", selection: $showBeforeAfter) {
                        Text("After Only").tag(false)
                        Text("Before & After").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, theme.spacingMD)

                    // Image comparison area
                    if showBeforeAfter {
                        ComparisonSliderView(
                            beforeImage: Image(systemName: "photo"),
                            afterImage: Image(systemName: "photo.fill")
                        )
                        .aspectRatio(3/4, contentMode: .fit)
                        .padding(.horizontal, theme.spacingMD)
                    } else {
                        // After only
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: visualization.colorHex).opacity(0.3))
                            .aspectRatio(3/4, contentMode: .fit)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.mutedForeground.opacity(0.5))
                            )
                            .padding(.horizontal, theme.spacingMD)
                    }

                    // Color info card
                    VStack(spacing: theme.spacingMD) {
                        HStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: theme.radiusMD)
                                .fill(Color(hex: visualization.colorHex))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    RoundedRectangle(cornerRadius: theme.radiusMD)
                                        .stroke(theme.border, lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Selected Color")
                                    .font(theme.micro)
                                    .textCase(.uppercase)
                                    .tracking(0.5)
                                    .foregroundStyle(theme.mutedForeground)
                                Text(visualization.colorName)
                                    .font(theme.headline)
                                Text("Benjamin Moore \u{00B7} \(visualization.colorCode)")
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }

                            Spacer()

                            Button {} label: {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(theme.primary)
                                    .frame(width: 40, height: 40)
                                    .background(theme.primary.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }

                        Divider()

                        HStack {
                            Label("Target: \(visualization.surface)", systemImage: "square.split.diagonal")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                            Spacer()
                            Label("Lighting: Afternoon Sun", systemImage: "sun.max")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                        }
                    }
                    .padding(theme.spacingMD)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radiusLG)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .padding(.horizontal, theme.spacingMD)

                    // Action buttons
                    HStack(spacing: theme.spacingSM) {
                        ActionTile(icon: "cart", label: "Order Swatch")
                        ActionTile(icon: "square.and.arrow.up", label: "Share Result")
                    }
                    .padding(.horizontal, theme.spacingMD)
                    .padding(.bottom, theme.spacingLG)
                }
            }

            FloatingActionBar {
                AppButton("Get Expert Consultation", variant: .cta, icon: "arrow.right") {}
            }
        }
        .navigationTitle(visualization.roomName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {} label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 40, height: 40)
                        .background(theme.muted.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
    }
}

private struct ActionTile: View {
    @Environment(Theme.self) private var theme
    let icon: String
    let label: String

    var body: some View {
        Button {} label: {
            VStack(spacing: theme.spacingSM) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.primary)
                Text(label)
                    .font(theme.micro)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.foreground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, theme.spacingMD)
            .background(theme.muted)
            .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radiusLG)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
