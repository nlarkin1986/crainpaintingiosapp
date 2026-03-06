import SwiftUI

struct ComparisonSliderView: View {
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
                        .fill(.white)
                        .frame(width: 2)
                        .shadow(color: .black.opacity(0.3), radius: 4)

                    Circle()
                        .fill(.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: .black.opacity(0.2), radius: 6)
                        .overlay(
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color(hex: "0D9488"))
                        )
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "0D9488"), lineWidth: 2)
                        )
                }
                .position(x: max(0, min(currentX, width)), y: geo.size.height / 2)

                // Labels
                HStack {
                    Text("BEFORE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.4))
                        .clipShape(Capsule())
                        .padding(16)

                    Spacer()

                    Text("AFTER")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0D9488").opacity(0.8))
                        .clipShape(Capsule())
                        .padding(16)
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
                        sliderPosition = max(0, min(1, newPosition))
                    }
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .drawingGroup()
    }
}
