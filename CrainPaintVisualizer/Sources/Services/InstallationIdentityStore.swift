import Foundation
import Security

enum InstallationIdentityError: LocalizedError {
    case readFailed(OSStatus)
    case writeFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .readFailed:
            return "We couldn't access the device identity used for preview generation."
        case .writeFailed:
            return "We couldn't save the device identity used for preview generation."
        }
    }
}

struct InstallationIdentityStore {
    private let service = "com.crainpaintvisualizer.installation-id"
    private let account = "default"

    func installationID() throws -> String {
        if let existing = try readInstallationID() {
            return existing
        }

        let generated = UUID().uuidString.lowercased()
        try saveInstallationID(generated)
        return generated
    }

    private func readInstallationID() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard
                let data = result as? Data,
                let value = String(data: data, encoding: .utf8),
                !value.isEmpty
            else {
                return nil
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw InstallationIdentityError.readFailed(status)
        }
    }

    private func saveInstallationID(_ value: String) throws {
        let data = Data(value.utf8)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        if updateStatus != errSecItemNotFound {
            throw InstallationIdentityError.writeFailed(updateStatus)
        }

        var createQuery = query
        createQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(createQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw InstallationIdentityError.writeFailed(addStatus)
        }
    }
}

enum AppRuntimeInfo {
    static var versionHeader: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (.some(version), .some(build)) where !version.isEmpty && !build.isEmpty && version != build:
            return "\(version) (\(build))"
        case let (.some(version), _ ) where !version.isEmpty:
            return version
        case let (_, .some(build)) where !build.isEmpty:
            return build
        default:
            return "unknown"
        }
    }
}
