import CoreTransferable
import Foundation
import UniformTypeIdentifiers

struct PhotoPixelSize: Codable, Hashable, Sendable {
    let width: Int
    let height: Int

    init(width: Int, height: Int) {
        self.width = max(width, 1)
        self.height = max(height, 1)
    }
}

struct PhotoAssetReference: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let fingerprint: String
    let originalPath: String
    let workingPath: String
    let uploadPath: String
    let originalPixelSize: PhotoPixelSize
    let workingPixelSize: PhotoPixelSize
    let createdAt: Date

    var originalURL: URL { URL(fileURLWithPath: originalPath) }
    var workingURL: URL { URL(fileURLWithPath: workingPath) }
    var uploadURL: URL { URL(fileURLWithPath: uploadPath) }
}

struct PhotoAsset: Identifiable, Hashable, Sendable {
    let id: String
    let fingerprint: String
    let originalURL: URL
    let workingURL: URL
    let uploadURL: URL
    let originalPixelSize: PhotoPixelSize
    let workingPixelSize: PhotoPixelSize
    let createdAt: Date

    init(reference: PhotoAssetReference) {
        id = reference.id
        fingerprint = reference.fingerprint
        originalURL = reference.originalURL
        workingURL = reference.workingURL
        uploadURL = reference.uploadURL
        originalPixelSize = reference.originalPixelSize
        workingPixelSize = reference.workingPixelSize
        createdAt = reference.createdAt
    }

    var reference: PhotoAssetReference {
        PhotoAssetReference(
            id: id,
            fingerprint: fingerprint,
            originalPath: originalURL.path,
            workingPath: workingURL.path,
            uploadPath: uploadURL.path,
            originalPixelSize: originalPixelSize,
            workingPixelSize: workingPixelSize,
            createdAt: createdAt
        )
    }
}

struct ImportedPhoto: Transferable, Sendable {
    let fileURL: URL
    let isOriginalFile: Bool

    init(fileURL: URL, isOriginalFile: Bool = false) {
        self.fileURL = fileURL
        self.isOriginalFile = isOriginalFile
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            ImportedPhoto(fileURL: received.file, isOriginalFile: false)
        }
    }
}
