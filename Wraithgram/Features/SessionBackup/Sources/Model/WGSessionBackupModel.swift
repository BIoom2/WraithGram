import Foundation
import Postbox
import TelegramCore

/// The Keychain value: byte-compatible with Swiftgram's `SessionBackup` (same property names, plain
/// `JSONEncoder` / `JSONDecoder`), so what the old client wrote can be read and the other way round.
struct WGSessionBackup: Codable {
    var name: String?
    var date: Date
    var accountRecord: AccountRecord<TelegramAccountManagerTypes.Attribute>
}

typealias WGAccountRecord = AccountRecord<TelegramAccountManagerTypes.Attribute>

/// Plain record rules, no UI and no Keychain.
enum WGSessionBackupRules {
    static func isLoggedOut(_ record: WGAccountRecord) -> Bool {
        return record.attributes.contains(where: { attribute in
            if case .loggedOut = attribute {
                return true
            }
            return false
        })
    }

    static func backupData(of record: WGAccountRecord) -> AccountBackupData? {
        for attribute in record.attributes {
            if case let .backupData(value) = attribute {
                return value.data
            }
        }
        return nil
    }

    /// The account's user id; nil for a record without backup data or without a real id.
    static func peerId(of record: WGAccountRecord) -> Int64? {
        guard let peerId = WGSessionBackupRules.backupData(of: record)?.peerId, peerId != 0 else {
            return nil
        }
        return peerId
    }

    /// Records worth a backup: signed in, with a real peer id.
    static func backupCandidates(_ records: [WGAccountRecord]) -> [(peerId: Int64, record: WGAccountRecord)] {
        var result: [(peerId: Int64, record: WGAccountRecord)] = []
        for record in records where !WGSessionBackupRules.isLoggedOut(record) {
            if let peerId = WGSessionBackupRules.peerId(of: record) {
                result.append((peerId, record))
            }
        }
        return result
    }

    /// The sort order for a restored record: after every existing one.
    static func nextSortOrder(_ records: [WGAccountRecord]) -> Int32 {
        var maximum: Int32 = 0
        for record in records {
            for attribute in record.attributes {
                if case let .sortOrder(value) = attribute {
                    maximum = max(maximum, value.order)
                }
            }
        }
        return maximum + 1
    }

    /// Attributes of a restored record: the stored ones with the sort order moved to the end and no logged-out mark.
    static func restoredAttributes(of record: WGAccountRecord, sortOrder: Int32) -> [TelegramAccountManagerTypes.Attribute] {
        var attributes = record.attributes.filter { attribute in
            switch attribute {
            case .sortOrder, .loggedOut:
                return false
            default:
                return true
            }
        }
        attributes.append(.sortOrder(AccountSortOrderAttribute(order: sortOrder)))
        return attributes
    }
}
