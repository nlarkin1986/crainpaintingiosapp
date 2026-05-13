import SwiftUI
import PhotosUI
import StoreKit

@MainActor
@Observable
final class VisualizerViewModel {
    enum GenerationState: Equatable {
        case idle
        case preparing
        case generating(current: Int, total: Int, colorName: String)
        case completed
        case gated
        case failed(String)
    }

    var selectedBrand: PaintBrand = .benjaminMoore
    var selectedColors: [PaintColor] = []
    var photo: UIImage?
    var selectedSurface: SurfaceType?
    var customSurfaceText = ""
    var isCompressing = false
    var generatedVisualizations: [Visualization] = []
    var generationState: GenerationState = .idle
    var usage: VisualizationUsage = .initial
    var showPaywall = false
    var isPurchasing = false
    var purchaseMessage: String?
    var visualizerProductDisplayPrice: String?

    private var compressionTask: Task<Void, Never>?
    private var compressionRequestID = UUID()
    private let userDefaults: UserDefaults
    private let processInfo: ProcessInfo
    private let deviceId: String
    private let apiClient: APIClient?
    private let productId: String
    private var entitlementJWS: String?

    var canAddColor: Bool { selectedColors.count < 5 }
    var hasPhoto: Bool { photo != nil }
    var hasVisualizerEntitlement: Bool { usage.hasEntitlement || entitlementJWS != nil }
    var remainingFreeRenders: Int { max(usage.remainingFree, 0) }
    var isLocked: Bool { !hasVisualizerEntitlement && usage.completedCount >= usage.freeLimit }
    var isShowingGenerationPlaceholders: Bool {
        switch generationState {
        case .preparing, .generating:
            return true
        default:
            return false
        }
    }
    var surfaceDescription: String {
        if selectedSurface == .custom { return customSurfaceText }
        return selectedSurface?.rawValue ?? ""
    }

    init(userDefaults: UserDefaults = .standard, processInfo: ProcessInfo = .processInfo) {
        self.userDefaults = userDefaults
        self.processInfo = processInfo
        self.deviceId = DeviceIdentifier.current()
        self.productId = Bundle.main.object(forInfoDictionaryKey: "VISUALIZER_UNLOCK_PRODUCT_ID") as? String
            ?? "com.crainpainting.visualizer.pro.lifetime"
        self.usage = VisualizationUsage(
            completedCount: userDefaults.integer(forKey: "completedVisualizations"),
            freeLimit: 5,
            remainingFree: max(5 - userDefaults.integer(forKey: "completedVisualizations"), 0),
            hasEntitlement: userDefaults.bool(forKey: "visualizerEntitlementActive")
        )
        if let baseURL = APIEnvironment.baseURL {
            self.apiClient = APIClient(baseURL: baseURL)
        } else {
            self.apiClient = nil
        }

        if processInfo.arguments.contains("UITEST_SEED_PHOTO") {
            photo = Self.makeUITestImage()
        }

        Task {
            await refreshPurchases()
            await loadVisualizerProduct()
        }
    }

    func toggleColor(_ color: PaintColor) {
        if let index = selectedColors.firstIndex(of: color) {
            selectedColors.remove(at: index)
        } else if canAddColor {
            selectedColors.append(color)
        }
    }

    @discardableResult
    func addColor(_ color: PaintColor) -> Bool {
        guard !selectedColors.contains(color), canAddColor else { return false }
        if selectedColors.isEmpty {
            selectedBrand = color.brand
        }
        selectedColors.append(color)
        return true
    }

    func startFlow(with color: PaintColor) {
        compressionTask?.cancel()
        selectedBrand = color.brand
        selectedColors = [color]
        photo = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
        generatedVisualizations = []
        generationState = .idle
    }

    func isSelected(_ color: PaintColor) -> Bool {
        selectedColors.contains(color)
    }

    func setPhoto(from data: Data) {
        compressionTask?.cancel()
        let requestID = UUID()
        compressionRequestID = requestID
        isCompressing = true
        photo = nil

        compressionTask = Task(priority: .userInitiated) { [data] in
            let compressed = Self.compressImage(data: data, maxDimension: 2048, quality: 0.8)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                guard self.compressionRequestID == requestID else { return }
                self.photo = compressed
                self.isCompressing = false
            }
        }
    }

    func reset() {
        compressionTask?.cancel()
        selectedBrand = .benjaminMoore
        selectedColors = []
        photo = nil
        selectedSurface = nil
        customSurfaceText = ""
        isCompressing = false
        generatedVisualizations = []
        generationState = .idle
    }

    func generateVisualizationsIfNeeded() async {
        guard generatedVisualizations.isEmpty else { return }
        await generateVisualizations()
    }

    func generateVisualizations() async {
        guard let photo else {
            generationState = .failed("Add a room photo before generating.")
            return
        }

        guard !selectedColors.isEmpty else {
            generationState = .failed("Choose at least one paint color.")
            return
        }

        let surface = surfaceDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !surface.isEmpty else {
            generationState = .failed("Choose the surface you want to repaint.")
            return
        }

        if isLocked {
            generationState = .gated
            showPaywall = true
            return
        }

        if processInfo.arguments.contains("UITEST_SEED_PHOTO") {
            generatedVisualizations = selectedColors.enumerated().map { index, color in
                Visualization(
                    id: "generated-\(index)-\(color.id)",
                    colorName: color.name,
                    colorHex: color.hex,
                    colorCode: color.number,
                    roomName: roomName,
                    beforeImageName: "",
                    afterImageName: "",
                    surface: surface,
                    originalImageURL: nil,
                    resultImageURL: nil,
                    shareId: "uitest-\(index)",
                    isAIGenerated: true
                )
            }
            generationState = .completed
            return
        }

        guard let apiClient else {
            generationState = .failed("The visualization service is not configured on this build.")
            return
        }

        generationState = .preparing
        var completed: [Visualization] = []
        let total = selectedColors.count

        for (index, color) in selectedColors.enumerated() {
            if isLocked {
                generationState = .gated
                showPaywall = true
                break
            }

            generationState = .generating(current: index + 1, total: total, colorName: color.name)

            do {
                let response = try await apiClient.visualize(
                    image: photo,
                    color: color,
                    surface: selectedSurface == .custom ? "custom" : surface,
                    customInstruction: selectedSurface == .custom ? surface : nil,
                    deviceId: deviceId,
                    signedTransactionJWS: entitlementJWS
                )

                if let remoteUsage = response.usage {
                    updateUsage(remoteUsage)
                } else if !hasVisualizerEntitlement {
                    updateUsage(VisualizationUsage(
                        completedCount: usage.completedCount + 1,
                        freeLimit: usage.freeLimit,
                        remainingFree: max(usage.remainingFree - 1, 0),
                        hasEntitlement: false
                    ))
                }

                completed.append(Visualization(
                    id: response.shareId,
                    colorName: color.name,
                    colorHex: color.hex,
                    colorCode: color.number,
                    roomName: roomName,
                    beforeImageName: "",
                    afterImageName: "",
                    surface: surface,
                    originalImageURL: response.originalUrl,
                    resultImageURL: response.resultUrl,
                    shareId: response.shareId,
                    isAIGenerated: true
                ))
                generatedVisualizations = completed
            } catch APIClientError.freeLimitExceeded(let usage) {
                updateUsage(usage)
                generationState = .gated
                showPaywall = true
                return
            } catch APIClientError.offline {
                generationState = .failed("You appear to be offline. Reconnect and retry this render.")
                return
            } catch {
                generationState = .failed("We could not complete that AI render. Your free renders were not charged.")
                return
            }
        }

        generationState = completed.isEmpty ? .idle : .completed
    }

    func purchaseVisualizerUnlock() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        purchaseMessage = nil

        do {
            let products = try await Product.products(for: [productId])
            guard let product = products.first else {
                purchaseMessage = "Purchases are unavailable right now."
                isPurchasing = false
                return
            }

            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseMessage = "Purchase could not be verified."
                    isPurchasing = false
                    return
                }
                entitlementJWS = verification.jwsRepresentation
                try? await apiClient?.verifyStoreKitEntitlement(deviceId: deviceId, signedTransactionJWS: verification.jwsRepresentation)
                updateUsage(VisualizationUsage(
                    completedCount: usage.completedCount,
                    freeLimit: usage.freeLimit,
                    remainingFree: usage.remainingFree,
                    hasEntitlement: true
                ))
                await transaction.finish()
                showPaywall = false
                purchaseMessage = "Visualizer Pro is active."
            case .userCancelled:
                purchaseMessage = "Purchase canceled."
            case .pending:
                purchaseMessage = "Purchase is pending approval."
            @unknown default:
                purchaseMessage = "Purchase did not complete."
            }
        } catch {
            purchaseMessage = "Purchase failed. Please try again."
        }

        isPurchasing = false
    }

    func restorePurchases() async {
        purchaseMessage = nil
        do {
            try await AppStore.sync()
            await refreshPurchases()
            purchaseMessage = hasVisualizerEntitlement ? "Purchase restored." : "No active visualizer purchase was found."
        } catch {
            purchaseMessage = "Restore failed. Please try again."
        }
    }

    func refreshPurchases() async {
        var activeJWS: String?
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.productID == productId,
                  transaction.revocationDate == nil else {
                continue
            }
            activeJWS = entitlement.jwsRepresentation
            break
        }

        entitlementJWS = activeJWS
        updateUsage(VisualizationUsage(
            completedCount: usage.completedCount,
            freeLimit: usage.freeLimit,
            remainingFree: usage.remainingFree,
            hasEntitlement: activeJWS != nil || usage.hasEntitlement
        ))
    }

    private func loadVisualizerProduct() async {
        guard let products = try? await Product.products(for: [productId]),
              let product = products.first else { return }
        visualizerProductDisplayPrice = product.displayPrice
    }

    private func updateUsage(_ newUsage: VisualizationUsage) {
        usage = newUsage
        userDefaults.set(newUsage.completedCount, forKey: "completedVisualizations")
        userDefaults.set(newUsage.hasEntitlement, forKey: "visualizerEntitlementActive")
    }

    private var roomName: String {
        switch selectedSurface {
        case .cabinets: "Kitchen Cabinets"
        case .doors: "Front Entry"
        case .ceiling: "Ceiling Plan"
        case .trimBase: "Trim Refresh"
        case .accentWall: "Accent Wall"
        case .walls: "Current Room"
        case .custom:
            surfaceDescription.isEmpty ? "Custom Surface" : surfaceDescription
        case nil:
            "Current Room"
        }
    }

    private nonisolated static func compressImage(data: Data, maxDimension: CGFloat, quality: CGFloat) -> UIImage? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        guard let jpegData = resized.jpegData(compressionQuality: quality) else { return resized }
        if jpegData.count <= 3_500_000 { return UIImage(data: jpegData) ?? resized }

        // Iteratively reduce quality
        var q = quality - 0.1
        while q > 0.1 {
            if let data = resized.jpegData(compressionQuality: q), data.count <= 3_500_000 {
                return UIImage(data: data) ?? resized
            }
            q -= 0.1
        }
        return resized
    }

    private nonisolated static func makeUITestImage() -> UIImage {
        let size = CGSize(width: 1200, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.95, green: 0.92, blue: 0.88, alpha: 1).setFill()
            context.fill(rect)

            UIColor(red: 0.82, green: 0.78, blue: 0.72, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.height * 0.38))

            UIColor(red: 0.72, green: 0.68, blue: 0.62, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.14, y: size.height * 0.28, width: size.width * 0.72, height: size.height * 0.42))

            UIColor(red: 0.62, green: 0.58, blue: 0.52, alpha: 1).setFill()
            context.fill(CGRect(x: size.width * 0.22, y: size.height * 0.42, width: size.width * 0.18, height: size.height * 0.2))
        }
    }
}
