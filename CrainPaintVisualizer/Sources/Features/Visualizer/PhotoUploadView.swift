import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @Environment(Theme.self) private var theme
    @Environment(RouterPath.self) private var router
    @State private var visualizerVM = VisualizerViewModel()
    @State private var showCamera = false
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: theme.spacingMD) {
                    StepProgressView(steps: ["Color", "Photo", "Surface"], currentStep: 1)

                    Text("Upload your space")
                        .font(theme.title)
                        .foregroundStyle(theme.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, theme.spacingMD)

                    // Upload zone
                    if let photo = visualizerVM.photo {
                        // Photo loaded state
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: photo)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 250)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))

                            Button {
                                visualizerVM.photo = nil
                            } label: {
                                Text("Change Photo")
                                    .font(theme.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .padding(12)
                        }
                        .padding(.horizontal, theme.spacingMD)
                    } else if visualizerVM.isCompressing {
                        // Compressing state
                        VStack(spacing: theme.spacingSM) {
                            ProgressView()
                            Text("Preparing your photo...")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .background(theme.muted)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .padding(.horizontal, theme.spacingMD)
                    } else {
                        // Empty upload zone
                        VStack(spacing: theme.spacingMD) {
                            Image(systemName: "camera")
                                .font(.system(size: 48))
                                .foregroundStyle(theme.mutedForeground)

                            Text("Take or Upload Photo")
                                .font(theme.headline)
                                .foregroundStyle(theme.foreground)

                            Text("Capture or select a photo of the room you want to visualize")
                                .font(theme.caption)
                                .foregroundStyle(theme.mutedForeground)
                                .multilineTextAlignment(.center)

                            HStack(spacing: theme.spacingSM) {
                                AppButton("Camera", variant: .outline, icon: "camera") {
                                    showCamera = true
                                }
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    HStack(spacing: theme.spacingSM) {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Library")
                                            .font(theme.subhead)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .foregroundStyle(theme.foreground)
                                    .background(Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusMD))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: theme.radiusMD)
                                            .stroke(theme.border, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                        .padding(theme.spacingLG)
                        .frame(maxWidth: .infinity)
                        .background(theme.muted.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radiusLG))
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radiusLG)
                                .stroke(theme.border, style: StrokeStyle(lineWidth: 1.5, dash: [8]))
                        )
                        .padding(.horizontal, theme.spacingMD)
                    }

                    // Pro Tip
                    HStack(alignment: .top, spacing: theme.spacingSM) {
                        Image(systemName: "lightbulb")
                            .foregroundStyle(.yellow)
                        Text("Pro Tip: Use natural lighting and capture the full wall for best results.")
                            .font(theme.caption)
                            .foregroundStyle(theme.foreground)
                    }
                    .padding(theme.spacingSM)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: theme.radiusSM))
                    .padding(.horizontal, theme.spacingMD)
                }
            }

            FloatingActionBar {
                AppButton("Next Step", variant: .primary, icon: "arrow.right", isDisabled: !visualizerVM.hasPhoto) {
                    router.navigate(to: .surfacePicker)
                }
            }
        }
        .navigationTitle("Upload Photo")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            CameraView { image in
                visualizerVM.photo = image
            }
        }
        .onChange(of: selectedPhoto) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self) {
                    visualizerVM.setPhoto(from: data)
                }
            }
        }
    }
}
