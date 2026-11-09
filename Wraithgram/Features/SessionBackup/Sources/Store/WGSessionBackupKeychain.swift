import Foundation
import Security
import WGCore

/// The Keychain items of the backup: `kSecClassGenericPassword`, service
/// `<bundle id>.sessionsbackup`, account = the user id, value = `JSONEncoder` data of
/// `WGSessionBackup`. Readable only while the device is unlocked, no access group, not synchronized
/// — Swiftgram's layout. Blocking calls: run them off the main thread. Neither the values nor ids
/// are ever logged.
enum WGSessionBackupKeychain {
    struct Entry {
        let peerId: Int64
        let backup: WGSessionBackup
    }

    private static var service: String {
        return "\(Bundle.main.bundleIdentifier ?? "").sessionsbackup"
    }

    private static func baseQuery() -> [String: Any] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: WGSessionBackupKeychain.service
        ]
    }

    static func loadAll() -> [Entry] {
        var query = WGSessionBackupKeychain.baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess else {
            WGLog.warning("sessionBackup", "keychain read failed: \(status)")
            return []
        }
        guard let items = result as? [[String: Any]] else {
            return []
        }
        var entries: [Entry] = []
        let decoder = JSONDecoder()
        for item in items {
            guard let account = item[kSecAttrAccount as String] as? String, let peerId = Int64(account), let data = item[kSecValueData as String] as? Data else {
                continue
            }
            if let backup = try? decoder.decode(WGSessionBackup.self, from: data) {
                entries.append(Entry(peerId: peerId, backup: backup))
            }
        }
        return entries
    }

    /// Adds or replaces the item of `peerId`.
    @discardableResult
    static func save(peerId: Int64, backup: WGSessionBackup) -> Bool {
        guard let data = try? JSONEncoder().encode(backup) else {
            return false
        }
        var query = WGSessionBackupKeychain.baseQuery()
        query[kSecAttrAccount as String] = String(peerId)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }
        if updateStatus != errSecItemNotFound {
            WGLog.warning("sessionBackup", "keychain update failed: \(updateStatus)")
            return false
        }
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus != errSecSuccess {
            WGLog.warning("sessionBackup", "keychain add failed: \(addStatus)")
        }
        return addStatus == errSecSuccess
    }

    static func delete(peerId: Int64) {
        var query = WGSessionBackupKeychain.baseQuery()
        query[kSecAttrAccount as String] = String(peerId)
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            WGLog.warning("sessionBackup", "keychain delete failed: \(status)")
        }
    }

    static func deleteAll() {
        let status = SecItemDelete(WGSessionBackupKeychain.baseQuery() as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            WGLog.warning("sessionBackup", "keychain delete-all failed: \(status)")
        }
    }
}
