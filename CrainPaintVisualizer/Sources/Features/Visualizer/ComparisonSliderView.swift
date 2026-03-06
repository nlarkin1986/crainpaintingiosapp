import SwiftUI

struct ComparisonSliderView: View {
    @Environment(Theme.self) private var theme

    let beforeImage: Image
    let afterImage: Image

    @State private var sliderPosition: CGFloat = 0.5
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let currentX = (sliderPosition * width) + dragOffset

            ZStack {
                // After image (full)
                afterImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: geo.size.height)
                    .clipped()

                // Before image (clipped to left of slider)
                beforeImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: geo.size.height)
                    .clipped()
                    .mask(
                        HStack(spacing: 0) {
                            Rectangle()
                                .frame(width: max(0, min(currentX, width)))
                            Spacer(minLength: 0)
                        }
                    )

                // Slider line + handle
                ZStack {
                    Rectangle()
                        .fill(ColorTokens.visualizerSliderLine)
                        .frame(width: 2)
                        .shadow(color: .black.opacity(0.3), radius: 4)

                    Circle()
                        .fill(ColorTokens.visualizerSliderLine)
                        .frame(width: 44, height: 44)
                        .shadow(color: .black.opacity(0.2), radius: 6)
                        .overlay(
                            HStack(spacing: theme.space2) {
                                Image(systemName: "chevron.left")
                                Image(systemName: "chevron.right")
                            }
                            .font(theme.micro)
                            .foregroundStyle(theme.primary)
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.primary, lineWidth: 2)
                        )
                }
                .position(x: max(0, min(currentX, width)), y: geo.size.height / 2)

                // Labels
                HStack {
                    Text("BEFORE")
                        .font(theme.micro)
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space4)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())
                        .padding(theme.space16)

                    Spacer()

                    Text("AFTER")
                        .font(theme.micro)
                        .tracking(1)
                        .foregroundStyle(theme.actionPrimaryText)
                        .padding(.horizontal, theme.space12)
                        .padding(.vertical, theme.space4)
                        .background(theme.actionPrimary.opacity(0.88))
                        .clipShape(Capsule())
                        .padding(theme.space16)
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let newPosition = sliderPosition + (value.translation.width / width)
                        let clamped = max(0, min(1, newPosition))
                        // Snap to center if within 5%
                        let snapped = abs(clamped - 0.5) < 0.05 ? 0.5 : clamped
                        withAnimation(.spring(response: 0.25)) {
                            sliderPosition = snapped
                        }
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    sliderPosition = 0.5
                }
            }
            .sensoryFeedback(.impact(weight: .light), trigger: sliderPosition == 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: theme.radiusXL))
        .drawingGroup()
        .accessibilityElement()
        .accessibilityLabel("Before and after comparison slider")
        .accessibilityValue("\(Int(sliderPosition * 100))% showing before image")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: sliderPosition = min(1, sliderPosition + 0.1)
            case .decrement: sliderPosition = max(0, sliderPosition - 0.1)
            @unknown default: break
            }
        }
    }
}
