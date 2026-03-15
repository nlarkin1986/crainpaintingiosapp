import Foundation
import UIKit

struct PhotoIntakeResult {
    let asset: PhotoAssetReference
    let displayImage: UIImage?
}

protocol PhotoIntakeCoordinating: Sendable {
    func importPhoto(
        _ importedPhoto: ImportedPhoto,
        displayMaxPixelSize: Int
    ) async throws -> PhotoIntakeResult

    func importPhotoData(
        _ data: Data,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult

    func importImage(
        _ image: UIImage,
        originalFileExtension: String,
        displayMaxPixelSize: Int,
        fingerprintOverride: String?
    ) async throws -> PhotoIntakeResult

    func migrateLegacyPhotoData(
        _ data: Data,
        fileName: String?,
        fingerprint: String?
    ) async throws -> PhotoIntakeResult

    func loadDisplayImage(
        for reference: PhotoAssetReference?,
        maxPixelSize: Int
    ) async -> UIImage?

    func removeAsset(_ reference: PhotoAssetReference?) async
}

actor PhotoIntakeCoordinator: PhotoIntakeCoordinating {
    static let shared = PhotoIntakeCoordinator(processor: .shared)

    let processor: PhotoProcessingService

    init(processor: PhotoProcessingService = .shared) {
        self.processor = processor
    }

    func importPhoto(
        _ importedPhoto: ImportedPhoto,
        displayMaxPixelSize: Int = 1_600
    ) async throws -> PhotoIntakeResult {
        let asset = try await processor.importPhoto(importedPhoto)
        let displayImage = await processor.loadDisplayImage(for: asset, maxPixelSize: displayMaxPixelSize)
        return PhotoIntakeResult(asset: asset, displayImage: displayImage)
    }

    func importPhotoData(
        _ data: Data,
        originalFileExtension: String = "jpg",
        displayMaxPixelSize: Int = 1_600,
        fingerprintOverride: String? = nil
    ) async throws -> PhotoIntakeResult {
        let asset = try await processor.importPhotoData(
            data,
            originalFileExtension: originalFileExtension,
            fingerprintOverride: fingerprintOverride
        )
        let displayImage = await processor.loadDisplayImage(for: asset, maxPixelSize: displayMaxPixelSize)
        return PhotoIntakeResult(asset: asset, displayImage: displayImage)
    }

    func importImage(
        _ image: UIImage,
        originalFileExtension: String = "jpg",
        displayMaxPixelSize: Int = 1_600,
        fingerprintOverride: String? = nil
    ) async throws -> PhotoIntakeResult {
        let asset = try await processor.importImage(
            image,
            originalFileExtension: originalFileExtension,
            fingerprintOverride: fingerprintOverride
        )
        let displayImage = await processor.loadDisplayImage(for: asset, maxPixelSize: displayMaxPixelSize)
        return PhotoIntakeResult(asset: asset, displayImage: displayImage)
    }

    func migrateLegacyPhotoData(
        _ data: Data,
        fileName: String?,
        fingerprint: String?
    ) async throws -> PhotoIntakeResult {
        let fileExtension = URL(fileURLWithPath: fileName ?? "legacy-photo.jpg").pathExtension
        return try await importPhotoData(
            data,
            originalFileExtension: fileExtension,
            displayMaxPixelSize: 1_600,
            fingerprintOverride: fingerprint
        )
    }

    func loadDisplayImage(
        for reference: PhotoAssetReference?,
        maxPixelSize: Int = 1_600
    ) async -> UIImage? {
        await processor.loadDisplayImage(for: reference, maxPixelSize: maxPixelSize)
    }

    func loadTransientImage(
        from importedPhoto: ImportedPhoto,
        maxPixelSize: Int = 1_600
    ) async throws -> UIImage? {
        let result = try await importPhoto(importedPhoto, displayMaxPixelSize: maxPixelSize)
        await processor.removeAsset(result.asset)
        return result.displayImage
    }

    func loadTransientImage(
        from data: Data,
        originalFileExtension: String = "jpg",
        maxPixelSize: Int = 1_600
    ) async throws -> UIImage? {
        let result = try await importPhotoData(
            data,
            originalFileExtension: originalFileExtension,
            displayMaxPixelSize: maxPixelSize
        )
        await processor.removeAsset(result.asset)
        return result.displayImage
    }

    func removeAsset(_ reference: PhotoAssetReference?) async {
        await processor.removeAsset(reference)
    }
}
