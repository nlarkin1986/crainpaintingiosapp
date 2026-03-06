import SwiftUI

struct ColorMatcherView: View {
    @Environment(Theme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @State private var isAnalyzing = true

    // Mock match data
    private let matches: [(String, String, String, Int)] = [
        ("Hale Navy", "HC-172", "3C4659", 96),
        ("Van Deusen Blue", "HC-154", "3F5268", 89),
        ("Naval", "SW 6244", "2E384D", 84),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Align object in frame")
                        .font(theme.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    Spacer()
                    Button {} label: {
                        Image(systemName: "bolt")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()

                // Camera area with crop frame
                ZStack {
                    // Mock camera bg
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))

                    // Crop frame
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 220, height: 220)
                        .overlay(
                            // Corner brackets
                            CropCorners()
                                .stroke(theme.primary, lineWidth: 3)
                        )

                    // Center crosshair
                    Circle()
                        .fill(theme.primary)
                        .frame(width: 12, height: 12)
                        .opacity(isAnalyzing ? 1 : 0.5)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: isAnalyzing)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Analyzing indicator
                if isAnalyzing {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 8, height: 8)
                        Text("Analyzing Color...")
                            .font(theme.caption)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }

                // Bottom sheet
                VStack(spacing: theme.spacingMD) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 36, height: 4)
                        .padding(.top, 8)

                    HStack {
                        Text("Matches Found")
                            .font(theme.headline)
                        Spacer()
                        Text("3 closest cross-brand matches")
                            .font(theme.caption)
                            .foregroundStyle(theme.mutedForeground)
                    }

                    ForEach(Array(matches.enumerated()), id: \.offset) { index, match in
                        HStack(spacing: theme.spacingSM) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: match.2))
                                .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(match.0)
                                    .font(theme.subhead)
                                    .fontWeight(.semibold)
                                Text(match.1)
                                    .font(theme.caption)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            Spacer()

                            Text("\(match.3)%")
                                .font(theme.subhead)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.primary)

                            Button {} label: {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(theme.primary)
                            }
                        }
                        .padding(theme.spacingSM)
                        .background(index == 0 ? theme.primary.opacity(0.05) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                    }

                    AppButton("Retake Photo", variant: .outline, icon: "camera") {
                        // Reset
                    }
                }
                .padding(.horizontal, theme.spacingMD)
                .padding(.bottom, theme.spacingLG)
                .background(theme.card)
                .clipShape(
                    UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20)
                )
            }
        }
    }
}

private struct CropCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let len: CGFloat = 24
        var path = Path()
        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))
        // Top-right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))
        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))
        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))
        return path
    }
}
