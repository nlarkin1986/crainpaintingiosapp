import CryptoKit
import Foundation
import ImageIO
import UIKit
import UniformTypeIdentifiers

struct PhotoUploadRecipe: Sendable {
    let maxDimension: Int
    let minimumDimension: Int
    let maxBytes: Int
    let qualities: [Double]

    static let visualization = PhotoUploadRecipe(
        maxDimension: 2_048,
        minimumDimension: 960,
        maxBytes: 4_100_000,
        qualities: [0.9, 0.82, 0.74, 0.66, 0.58, 0.5, 0.42, 0.34]
    )

    static let colorMatch = PhotoUploadRecipe(
        maxDimension: 1_600,
        minimumDimension: 768,
        maxBytes: 4_100_000,
        qualities: [0.82, 0.72, 0.62, 0.55, 0.48, 0.4]
    )
}

enum PhotoProcessingError: LocalizedError {
    case invalidImageData
    case missingUploadData
    case unableToEncodeImage

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "We couldn't decode that image."
        case .missingUploadData:
            return "We couldn't load the prepared upload image."
        case .unableToEncodeImage:
            return "We couldn't encode the processed image."
        }
    }
}

struct PhotoWorkingRepresentation {
    let image: UIImage
    let originalPixelSize: PhotoPixelSize
    let workingPixelSize: PhotoPixelSize
}

actor PhotoProcessingService {
    static let shared = PhotoProcessingService()

    private let rootDirectory: URL
    private let originalsDirectory: URL
    private let workingDirectory: URL
    private let uploadsDirectory: URL
    private let cache = NSCache<NSString, UIImage>()
    private var cacheKeys = Set<String>()

    init(rootDirectory: URL = AppStorage.fileURL(for: "photo-assets")) {
        self.rootDirectory = rootDirectory
        originalsDirectory = rootDirectory.appendingPathComponent("originals", isDirectory: true)
        workingDirectory = rootDirectory.appendingPathComponent("working", isDirectory: true)
        uploadsDirectory = rootDirectory.appendingPathComponent("uploads", isDirectory: true)

        let manager = FileManager.default
        for directory in [rootDirectory, originalsDirectory, workingDirectory, uploadsDirectory] {
            if !manager.fileExists(atPath: directory.path) {
                try? manager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }

    func importPhoto(
        _ importedPhoto: ImportedPhoto,
        fingerprintOverride: String? = nil
    ) async throws -> PhotoAssetReference {
        let fileExtension = Self.normalizedFileExtension(importedPhoto.fileURL.pathExtension)
        let data = try Data(contentsOf: importedPhoto.fileURL)
        return try await createAsset(
            from: data,
            originalFileExtension: fileExtension,
            fingerprintOverride: fingerprintOverride
        )
    }

    func importPhotoData(
        _ data: Data,
        originalFileExtension: String = "jpg",
        fingerprintOverride: String? = nil
    ) async throws -> PhotoAssetReference {
        try await createAsset(
            from: data,
            originalFileExtension: Self.normalizedFileExtension(originalFileExtension),
            fingerprintOverride: fingerprintOverride
        )
    }

    func importImage(
        _ image: UIImage,
        originalFileExtension: String = "jpg",
        fingerprintOverride: String? = nil
    ) async throws -> PhotoAssetReference {
        let encodedData = try await Self.detached(priority: .userInitiated) {
            guard let data = Self.originalImageData(for: image, fileExtension: originalFileExtension) else {
                throw PhotoProcessingError.unableToEncodeImage
            }
            return data
        }

        return try await importPhotoData(
            encodedData,
            originalFileExtension: originalFileExtension,
            fingerprintOverride: fingerprintOverride
        )
    }

    func asset(for reference: PhotoAssetReference) -> PhotoAsset {
        PhotoAsset(reference: reference)
    }

    func uploadData(for reference: PhotoAssetReference) async throws -> Data {
        guard FileManager.default.fileExists(atPath: reference.uploadURL.path) else {
            throw PhotoProcessingError.missingUploadData
        }
        return try Data(contentsOf: reference.uploadURL)
    }

    func loadDisplayImage(for reference: PhotoAssetReference?, maxPixelSize: Int) async -> UIImage? {
        guard let reference else { return nil }

        let cacheKey = NSString(string: "\(reference.workingPath)|\(maxPixelSize)")
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let workingPath = reference.workingPath
        let image = await Self.detached(priority: .userInitiated) {
            Self.downsampledImage(at: URL(fileURLWithPath: workingPath), maxPixelSize: maxPixelSize)
                ?? UIImage(contentsOfFile: workingPath)
        }

        if let image {
            cache.setObject(image, forKey: cacheKey)
            cacheKeys.insert(cacheKey as String)
        }

        return image
    }

    func prepareUploadData(
        from image: UIImage,
        recipe: PhotoUploadRecipe
    ) async throws -> Data {
        try await Self.detached(priority: .userInitiated) {
            guard let data = Self.preparedUploadData(from: image, recipe: recipe) else {
                throw PhotoProcessingError.unableToEncodeImage
            }
            return data
        }
    }

    func fingerprint(for image: UIImage) async -> String? {
        await Self.detached(priority: .userInitiated) {
            VisualizationRequestFingerprint.photoFingerprint(for: image)
        }
    }

    func removeAsset(_ reference: PhotoAssetReference?) async {
        guard let reference else { return }
        let manager = FileManager.default

        for path in [reference.originalPath, reference.workingPath, reference.uploadPath] {
            if manager.fileExists(atPath: path) {
                try? manager.removeItem(atPath: path)
            }
        }

        let cachePrefix = "\(reference.workingPath)|"
        let keysToRemove = cacheKeys.filter { $0.hasPrefix(cachePrefix) }
        for key in keysToRemove {
            cache.removeObject(forKey: NSString(string: key))
            cacheKeys.remove(key)
        }
    }

    private func createAsset(
        from data: Data,
        originalFileExtension: String,
        fingerprintOverride: String?
    ) async throws -> PhotoAssetReference {
        let originalsDirectory = self.originalsDirectory
        let workingDirectory = self.workingDirectory
        let uploadsDirectory = self.uploadsDirectory

        return try await Self.detached(priority: .userInitiated) {
            try Self.createAssetSync(
                data: data,
                originalFileExtension: originalFileExtension,
                fingerprintOverride: fingerprintOverride,
                originalsDirectory: originalsDirectory,
                workingDirectory: workingDirectory,
                uploadsDirectory: uploadsDirectory
            )
        }
    }

    private static func createAssetSync(
        data: Data,
        originalFileExtension: String,
        fingerprintOverride: String?,
        originalsDirectory: URL,
        workingDirectory: URL,
        uploadsDirectory: URL
    ) throws -> PhotoAssetReference {
        let workingRepresentation = try makeWorkingRepresentation(from: data, maxDimension: 2_048)
        let workingImage = workingRepresentation.image
        let originalPixelSize = workingRepresentation.originalPixelSize

        let id = UUID().uuidString.lowercased()
        let originalURL = originalsDirectory.appendingPathComponent("\(id)-original.\(originalFileExtension)")
        let workingURL = workingDirectory.appendingPathComponent("\(id)-working.jpg")
        let uploadURL = uploadsDirectory.appendingPathComponent("\(id)-upload.jpg")

        try data.write(to: originalURL, options: .atomic)

        guard let workingData = workingImage.jpegData(compressionQuality: 0.9) else {
            throw PhotoProcessingError.unableToEncodeImage
        }
        try workingData.write(to: workingURL, options: .atomic)

        guard let uploadData = preparedUploadData(from: workingImage, recipe: .visualization) else {
            throw PhotoProcessingError.unableToEncodeImage
        }
        try uploadData.write(to: uploadURL, options: .atomic)

        let fingerprint = fingerprintOverride
            ?? VisualizationRequestFingerprint.photoFingerprint(for: workingImage)
            ?? sha256Hex(for: uploadData)

        return PhotoAssetReference(
            id: id,
            fingerprint: fingerprint,
            originalPath: originalURL.path,
            workingPath: workingURL.path,
            uploadPath: uploadURL.path,
            originalPixelSize: originalPixelSize,
            workingPixelSize: workingRepresentation.workingPixelSize,
            createdAt: .now
        )
    }

    static func makeWorkingRepresentation(
        from data: Data,
        maxDimension: Int
    ) throws -> PhotoWorkingRepresentation {
        guard
            let source = CGImageSourceCreateWithData(
                data as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary
            )
        else {
            throw PhotoProcessingError.invalidImageData
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let originalPixelSize = PhotoPixelSize(
            width: properties?[kCGImagePropertyPixelWidth] as? Int ?? maxDimension,
            height: properties?[kCGImagePropertyPixelHeight] as? Int ?? maxDimension
        )

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: max(maxDimension, 1),
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw PhotoProcessingError.invalidImageData
        }

        let downsampledImage = UIImage(cgImage: cgImage)
        let workingImage = opaqueImage(from: downsampledImage)

        return PhotoWorkingRepresentation(
            image: workingImage,
            originalPixelSize: originalPixelSize,
            workingPixelSize: PhotoPixelSize(width: cgImage.width, height: cgImage.height)
        )
    }

    private static func originalImageData(for image: UIImage, fileExtension: String) -> Data? {
        switch normalizedFileExtension(fileExtension) {
        case "png":
            return image.pngData()
        case "heic", "heif":
            if let cgImage = image.cgImage {
                let mutableData = NSMutableData()
                guard
                    let destination = CGImageDestinationCreateWithData(
                        mutableData,
                        UTType.heic.identifier as CFString,
                        1,
                        nil
                    )
                else {
                    return image.jpegData(compressionQuality: 0.95)
                }
                CGImageDestinationAddImage(destination, cgImage, nil)
                guard CGImageDestinationFinalize(destination) else {
                    return image.jpegData(compressionQuality: 0.95)
                }
                return mutableData as Data
            }
            return image.jpegData(compressionQuality: 0.95)
        default:
            return image.jpegData(compressionQuality: 0.95)
        }
    }

    private static func preparedUploadData(from image: UIImage, recipe: PhotoUploadRecipe) -> Data? {
        var candidate = resizeIfNeeded(image: image, maxDimension: CGFloat(recipe.maxDimension))
        var lowestQualityData: Data?

        while true {
            for quality in recipe.qualities {
                guard let data = candidate.jpegData(compressionQuality: quality) else { continue }
                lowestQualityData = data
                if data.count <= recipe.maxBytes {
                    return data
                }
            }

            let largestSide = max(candidate.size.width, candidate.size.height)
            guard largestSide > CGFloat(recipe.minimumDimension) else {
                return lowestQualityData
            }

            let nextDimension = max(largestSide * 0.85, CGFloat(recipe.minimumDimension))
            let resized = resizeIfNeeded(image: candidate, maxDimension: nextDimension)
            guard resized.size != candidate.size else {
                return lowestQualityData
            }
            candidate = resized
        }
    }

    private static func resizeIfNeeded(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalSize = image.size
        let largestSide = max(originalSize.width, originalSize.height)
        guard largestSide > maxDimension else { return image }

        let scale = maxDimension / largestSide
        let resizedSize = CGSize(
            width: max(1, floor(originalSize.width * scale)),
            height: max(1, floor(originalSize.height * scale))
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: resizedSize, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: resizedSize))
            image.draw(in: CGRect(origin: .zero, size: resizedSize))
        }
    }

    private static func opaqueImage(from image: UIImage) -> UIImage {
        let size = CGSize(
            width: max(image.size.width, 1),
            height: max(image.size.height, 1)
        )
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
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

    private static func normalizedFileExtension(_ fileExtension: String) -> String {
        let trimmed = fileExtension.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.isEmpty ? "jpg" : trimmed
    }

    private static func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func detached<T: Sendable>(
        priority: TaskPriority,
        operation: @escaping @Sendable () throws -> T
    ) async throws -> T {
        try await Task.detached(priority: priority, operation: operation).value
    }

    private static func detached<T>(
        priority: TaskPriority,
        operation: @escaping @Sendable () -> T
    ) async -> T {
        await Task.detached(priority: priority, operation: operation).value
    }
}
