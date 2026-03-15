import SwiftUI
import PhotosUI

struct FullscreenImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: Image
    let title: String
    var uiImage: UIImage?
    var assetName: String?

    @State private var renderedUIImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showSavedAlert = false
    @State private var savedAlertMessage = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            image
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnifyGesture()
                        .onChanged { value in
                            scale = lastScale * value.magnification
                        }
                        .onEnded { _ in
                            lastScale = max(scale, 1.0)
                            scale = max(scale, 1.0)
                            if scale == 1.0 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = .zero
                                    lastOffset = .zero
                                }
                            }
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    guard scale > 1.0 else { return }
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring(duration: 0.3)) {
                        if scale > 1.0 {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 3.0
                            lastScale = 3.0
                        }
                    }
                }

            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")

                    Spacer()

                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                if let shareImage = resolvedUIImage {
                    HStack(spacing: 32) {
                        Button {
                            saveToPhotos(shareImage)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Save")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.white)
                        }

                        ShareLink(item: SwiftUIImageTransferable(image: shareImage), preview: SharePreview(title, image: Image(uiImage: shareImage))) {
                            VStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Share")
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.5))
                }
            }
        }
        .statusBarHidden()
        .onAppear {
            if renderedUIImage == nil {
                if let uiImage {
                    renderedUIImage = uiImage
                } else if let assetName, let img = UIImage(named: assetName) {
                    renderedUIImage = img
                }
            }
        }
        .overlay {
            if showSavedAlert {
                savedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var resolvedUIImage: UIImage? {
        renderedUIImage ?? uiImage
    }

    private var savedToast: some View {
        VStack {
            Text(savedAlertMessage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(.top, 60)
            Spacer()
        }
    }

    private func saveToPhotos(_ img: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    savedAlertMessage = "Photo access denied"
                    showSavedAlert = true
                    dismissToast()
                }
                return
            }
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
            DispatchQueue.main.async {
                savedAlertMessage = "Saved to Photos"
                withAnimation { showSavedAlert = true }
                dismissToast()
            }
        }
    }

    private func dismissToast() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSavedAlert = false }
        }
    }
}

// MARK: - Transferable wrapper for ShareLink

struct SwiftUIImageTransferable: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = item.image.pngData() else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
    }
}

// MARK: - View modifier for tappable fullscreen images

struct TappableImageModifier: ViewModifier {
    let image: Image
    let title: String
    var uiImage: UIImage?
    var assetName: String?

    @State private var showFullscreen = false

    func body(content: Content) -> some View {
        Button {
            showFullscreen = true
        } label: {
            content
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenImageViewer(
                image: image,
                title: title,
                uiImage: uiImage,
                assetName: assetName
            )
        }
    }
}

extension View {
    func tappableImage(_ image: Image, title: String = "", uiImage: UIImage? = nil, assetName: String? = nil) -> some View {
        modifier(TappableImageModifier(image: image, title: title, uiImage: uiImage, assetName: assetName))
    }
}
