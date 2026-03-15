import Foundation
import ImageIO
import SwiftUI
import UIKit

struct Visualization: Identifiable, Hashable, Codable {
    let id: String
    let projectID: String?
    let remoteVisualizationID: String?
    let colorName: String
    let colorHex: String
    let colorCode: String
    let roomName: String
    let beforeImageName: String?
    let afterImageName: String?
    let beforeImagePath: String?
    let afterImagePath: String?
    let beforeFullImagePath: String?
    let afterFullImagePath: String?
    let originalURL: String?
    let resultURL: String?
    let shareID: String?
    let surface: String
    let brand: PaintBrand
    let createdAt: Date

    private struct StoragePayload: Codable {
        let id: String
        let projectID: String?
        let remoteVisualizationID: String?
        let colorName: String
        let colorHex: String
        let colorCode: String
        let roomName: String
        let beforeImageName: String?
        let afterImageName: String?
        let beforeImagePath: String?
        let afterImagePath: String?
        let beforeFullImagePath: String?
        let afterFullImagePath: String?
        let originalURL: String?
        let resultURL: String?
        let shareID: String?
        let surface: String
        let brand: PaintBrand?
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case projectID
            case remoteVisualizationID
            case colorName
            case colorHex
            case colorCode
            case roomName
            case beforeImageName
            case afterImageName
            case beforeImagePath
            case afterImagePath
            case beforeFullImagePath
            case afterFullImagePath
            case originalURL
            case resultURL
            case shareID
            case surface
            case brand
            case createdAt
        }

        init(
            id: String,
            projectID: String?,
            remoteVisualizationID: String?,
            colorName: String,
            colorHex: String,
            colorCode: String,
            roomName: String,
            beforeImageName: String?,
            afterImageName: String?,
            beforeImagePath: String?,
            afterImagePath: String?,
            beforeFullImagePath: String?,
            afterFullImagePath: String?,
            originalURL: String?,
            resultURL: String?,
            shareID: String?,
            surface: String,
            brand: PaintBrand?,
            createdAt: Date
        ) {
            self.id = id
            self.projectID = projectID
            self.remoteVisualizationID = remoteVisualizationID
            self.colorName = colorName
            self.colorHex = colorHex
            self.colorCode = colorCode
            self.roomName = roomName
            self.beforeImageName = beforeImageName
            self.afterImageName = afterImageName
            self.beforeImagePath = beforeImagePath
            self.afterImagePath = afterImagePath
            self.beforeFullImagePath = beforeFullImagePath
            self.afterFullImagePath = afterFullImagePath
            self.originalURL = originalURL
            self.resultURL = resultURL
            self.shareID = shareID
            self.surface = surface
            self.brand = brand
            self.createdAt = createdAt
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            projectID = try container.decodeIfPresent(String.self, forKey: .projectID)
            remoteVisualizationID = try container.decodeIfPresent(String.self, forKey: .remoteVisualizationID)
            colorName = try container.decode(String.self, forKey: .colorName)
            colorHex = try container.decode(String.self, forKey: .colorHex)
            colorCode = try container.decode(String.self, forKey: .colorCode)
            roomName = try container.decode(String.self, forKey: .roomName)
            beforeImageName = try container.decodeIfPresent(String.self, forKey: .beforeImageName)
            afterImageName = try container.decodeIfPresent(String.self, forKey: .afterImageName)
            beforeImagePath = try container.decodeIfPresent(String.self, forKey: .beforeImagePath)
            afterImagePath = try container.decodeIfPresent(String.self, forKey: .afterImagePath)
            beforeFullImagePath = try container.decodeIfPresent(String.self, forKey: .beforeFullImagePath)
            afterFullImagePath = try container.decodeIfPresent(String.self, forKey: .afterFullImagePath)
            originalURL = try container.decodeIfPresent(String.self, forKey: .originalURL)
            resultURL = try container.decodeIfPresent(String.self, forKey: .resultURL)
            shareID = try container.decodeIfPresent(String.self, forKey: .shareID)
            surface = try container.decode(String.self, forKey: .surface)
            brand = try container.decodeIfPresent(PaintBrand.self, forKey: .brand)

            if let timestamp = try? container.decode(Date.self, forKey: .createdAt) {
                createdAt = timestamp
            } else {
                let rawCreatedAt = try container.decode(String.self, forKey: .createdAt)
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let parsedDate = formatter.date(from: rawCreatedAt) {
                    createdAt = parsedDate
                } else if let parsedDate = ISO8601DateFormatter().date(from: rawCreatedAt) {
                    createdAt = parsedDate
                } else {
                    throw DecodingError.dataCorruptedError(
                        forKey: .createdAt,
                        in: container,
                        debugDescription: "Invalid ISO-8601 date string: \(rawCreatedAt)"
                    )
                }
            }
        }
    }

    init(
        id: String,
        projectID: String? = nil,
        remoteVisualizationID: String? = nil,
        colorName: String,
        colorHex: String,
        colorCode: String,
        roomName: String,
        beforeImageName: String? = nil,
        afterImageName: String? = nil,
        beforeImagePath: String? = nil,
        afterImagePath: String? = nil,
        beforeFullImagePath: String? = nil,
        afterFullImagePath: String? = nil,
        originalURL: String? = nil,
        resultURL: String? = nil,
        shareID: String? = nil,
        surface: String,
        brand: PaintBrand? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectID = projectID
        self.remoteVisualizationID = remoteVisualizationID
        self.colorName = colorName
        self.colorHex = colorHex
        self.colorCode = colorCode
        self.roomName = roomName
        self.beforeImageName = beforeImageName
        self.afterImageName = afterImageName
        self.beforeImagePath = beforeImagePath
        self.afterImagePath = afterImagePath
        self.beforeFullImagePath = beforeFullImagePath
        self.afterFullImagePath = afterFullImagePath
        self.originalURL = originalURL
        self.resultURL = resultURL
        self.shareID = shareID
        self.surface = surface
        self.brand = brand ?? Self.inferBrand(from: colorCode)
        self.createdAt = createdAt
    }

    var inferredBrand: PaintBrand {
        brand
    }

    var hasReferenceImages: Bool {
        beforeImageSource != nil && afterImageSource != nil
    }

    var asPaintColor: PaintColor {
        PaintColor(number: colorCode, name: colorName, family: "Curated", hex: colorHex, brand: inferredBrand)
    }

    var beforeImageSource: VisualizationImageSource? {
        VisualizationImageSource(filePath: beforeImagePath, assetName: beforeImageName)
    }

    var afterImageSource: VisualizationImageSource? {
        VisualizationImageSource(filePath: afterImagePath, assetName: afterImageName)
    }

    var beforeDetailImageSource: VisualizationImageSource? {
        VisualizationImageSource(filePath: beforeFullImagePath ?? beforeImagePath, assetName: beforeImageName)
    }

    var afterDetailImageSource: VisualizationImageSource? {
        VisualizationImageSource(filePath: afterFullImagePath ?? afterImagePath, assetName: afterImageName)
    }

    func imageSource(for role: VisualizationImageRole, preset: VisualizationImagePreset) -> VisualizationImageSource? {
        switch (role, preset) {
        case (.before, .detail):
            return beforeDetailImageSource
        case (.after, .detail):
            return afterDetailImageSource
        case (.before, _):
            return beforeImageSource
        case (.after, _):
            return afterImageSource
        }
    }

    init(from decoder: Decoder) throws {
        let payload = try StoragePayload(from: decoder)
        self.init(
            id: payload.id,
            projectID: payload.projectID,
            remoteVisualizationID: payload.remoteVisualizationID,
            colorName: payload.colorName,
            colorHex: payload.colorHex,
            colorCode: payload.colorCode,
            roomName: payload.roomName,
            beforeImageName: payload.beforeImageName,
            afterImageName: payload.afterImageName,
            beforeImagePath: payload.beforeImagePath,
            afterImagePath: payload.afterImagePath,
            beforeFullImagePath: payload.beforeFullImagePath,
            afterFullImagePath: payload.afterFullImagePath,
            originalURL: payload.originalURL,
            resultURL: payload.resultURL,
            shareID: payload.shareID,
            surface: payload.surface,
            brand: payload.brand,
            createdAt: payload.createdAt
        )
    }

    func encode(to encoder: Encoder) throws {
        try StoragePayload(
            id: id,
            projectID: projectID,
            remoteVisualizationID: remoteVisualizationID,
            colorName: colorName,
            colorHex: colorHex,
            colorCode: colorCode,
            roomName: roomName,
            beforeImageName: beforeImageName,
            afterImageName: afterImageName,
            beforeImagePath: beforeImagePath,
            afterImagePath: afterImagePath,
            beforeFullImagePath: beforeFullImagePath,
            afterFullImagePath: afterFullImagePath,
            originalURL: originalURL,
            resultURL: resultURL,
            shareID: shareID,
            surface: surface,
            brand: brand,
            createdAt: createdAt
        ).encode(to: encoder)
    }

    private static func inferBrand(from colorCode: String) -> PaintBrand {
        let normalized = colorCode
            .uppercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let condensed = normalized.replacingOccurrences(of: " ", with: "")

        if normalized.contains("SW") {
            return .sherwinWilliams
        }

        if condensed.hasPrefix("NO.") || condensed.hasPrefix("NO") {
            return .farrowBall
        }

        return .benjaminMoore
    }
}

struct VisualizationImageSource: Hashable, Sendable {
    let filePath: String?
    let assetName: String?

    init?(filePath: String?, assetName: String?) {
        if let filePath, !filePath.isEmpty {
            self.filePath = filePath
            self.assetName = nil
            return
        }

        if let assetName, !assetName.isEmpty {
            self.filePath = nil
            self.assetName = assetName
            return
        }

        return nil
    }

    fileprivate var cacheKey: String {
        if let filePath {
            return "file:\(filePath)"
        }
        if let assetName {
            return "asset:\(assetName)"
        }
        return "empty"
    }
}

enum VisualizationImageVariant: Hashable, Sendable {
    case sized(maxPixelSize: Int)
    case fullResolution

    fileprivate var cacheKey: String {
        switch self {
        case .fullResolution:
            return "full"
        case .sized(let maxPixelSize):
            return "sized:\(maxPixelSize)"
        }
    }
}

enum VisualizationImageRole: Hashable, Sendable {
    case before
    case after
}

enum VisualizationImagePreset: Hashable, Sendable {
    case homeFeature
    case savedGrid
    case galleryCard
    case jobCard
    case detail

    fileprivate var variant: VisualizationImageVariant {
        switch self {
        case .detail:
            return .fullResolution
        case .homeFeature:
            return .sized(maxPixelSize: 1_200)
        case .savedGrid:
            return .sized(maxPixelSize: 960)
        case .galleryCard:
            return .sized(maxPixelSize: 1_000)
        case .jobCard:
            return .sized(maxPixelSize: 520)
        }
    }
}

struct VisualizationShareLinks: Equatable {
    let sharePageURL: URL
    let designCardURL: URL
}

extension Visualization {
    var afterImageFileURL: URL? {
        afterDetailImageSource?.filePath.map(URL.init(fileURLWithPath:))
            ?? afterImageSource?.filePath.map(URL.init(fileURLWithPath:))
    }

    func shareLinks(baseURL: URL? = APIEnvironment.baseURL) -> VisualizationShareLinks? {
        guard
            let shareID,
            !shareID.isEmpty,
            let baseURL,
            let sharePageURL = Self.makeShareURL(baseURL: baseURL, path: "/share/\(shareID)"),
            let designCardURL = Self.makeShareURL(baseURL: baseURL, path: "/api/share/\(shareID)/card")
        else {
            return nil
        }

        return VisualizationShareLinks(
            sharePageURL: sharePageURL,
            designCardURL: designCardURL
        )
    }

    func shareActivityItems(
        image: UIImage,
        baseURL: URL? = APIEnvironment.baseURL
    ) -> [Any] {
        guard let sharePageURL = shareLinks(baseURL: baseURL)?.sharePageURL else {
            return [image]
        }

        return [image, sharePageURL]
    }

    private static func makeShareURL(baseURL: URL, path: String) -> URL? {
        let normalizedBase = baseURL.absoluteString.replacingOccurrences(of: "/+$", with: "", options: .regularExpression)
        return URL(string: "\(normalizedBase)\(path)")
    }
}

actor VisualizationImageRepository {
    static let shared = VisualizationImageRepository()

    private let cache = NSCache<NSString, UIImage>()

    func loadImage(from source: VisualizationImageSource?, variant: VisualizationImageVariant) async -> UIImage? {
        guard let source else { return nil }

        let cacheKey = NSString(string: "\(source.cacheKey)|\(variant.cacheKey)")
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        let image = await Self.runOffMain {
            Self.makeImage(from: source, variant: variant)
        }

        if let image {
            cache.setObject(image, forKey: cacheKey)
        }

        return image
    }

    func loadImage(
        for visualization: Visualization,
        role: VisualizationImageRole,
        preset: VisualizationImagePreset
    ) async -> UIImage? {
        await loadImage(from: source(for: visualization, role: role, preset: preset), variant: preset.variant)
    }

    func cachedImage(from source: VisualizationImageSource?, variant: VisualizationImageVariant) -> UIImage? {
        guard let source else { return nil }
        return cache.object(forKey: cacheKey(for: source, variant: variant))
    }

    func clearCache() {
        cache.removeAllObjects()
    }

    private func source(
        for visualization: Visualization,
        role: VisualizationImageRole,
        preset: VisualizationImagePreset
    ) -> VisualizationImageSource? {
        visualization.imageSource(for: role, preset: preset)
    }

    private func cacheKey(for source: VisualizationImageSource, variant: VisualizationImageVariant) -> NSString {
        NSString(string: "\(source.cacheKey)|\(variant.cacheKey)")
    }

    private static func makeImage(from source: VisualizationImageSource, variant: VisualizationImageVariant) -> UIImage? {
        if let filePath = source.filePath {
            switch variant {
            case .fullResolution:
                return UIImage(contentsOfFile: filePath)
            case .sized(let maxPixelSize):
                return downsampledImage(at: URL(fileURLWithPath: filePath), maxPixelSize: maxPixelSize)
                    ?? UIImage(contentsOfFile: filePath)
            }
        }

        if let assetName = source.assetName {
            return UIImage(named: assetName)
        }

        return nil
    }

    private static func downsampledImage(at url: URL, maxPixelSize: Int) -> UIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary) else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private static func runOffMain<T>(_ operation: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: operation())
            }
        }
    }
}

struct VisualizationLoadedImageView<Placeholder: View>: View {
    let visualization: Visualization
    let role: VisualizationImageRole
    let preset: VisualizationImagePreset
    let contentMode: ContentMode
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder()
            }
        }
        .task(id: taskKey) {
            image = nil
            image = await VisualizationImageRepository.shared.loadImage(
                for: visualization,
                role: role,
                preset: preset
            )
        }
    }

    private var taskKey: String {
        let sourceKey = visualization.imageSource(for: role, preset: preset)?.cacheKey ?? "empty"
        return "\(sourceKey)|\(preset.variant.cacheKey)"
    }
}
