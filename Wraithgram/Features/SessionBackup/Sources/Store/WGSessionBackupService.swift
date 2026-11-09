import Foundation
import SwiftSignalKit
import Postbox
import TelegramCore
import AccountContext
import WGCore

/// One row of the backup screen.
struct WGSessionBackupSession: Equatable {
    let peerId: Int64
    let name: String?
    let date: Date
    /// An account with this user id is signed in in the app right now.
    let isLoggedIn: Bool
}

/// The operations on the Keychain copy and on the account records. Keychain calls run on one serial
/// queue (the auto backup and the screen never interleave a read with a write); results come back on
/// the main queue. Only counts are logged.
enum WGSessionBackupService {
    private static let queue = Queue(name: "org.wraithgram.sessionBackup", qos: .utility)

    private static func accountRecords(_ accountManager: AccountManager<TelegramAccountManagerTypes>) -> Signal<[WGAccountRecord], NoError> {
        return accountManager.accountRecords()
        |> take(1)
        |> map { $0.records }
    }

    /// Display names of the signed-in accounts by user id (the saved one is kept when a name is unknown).
    private static func accountNames(_ sharedContext: SharedAccountContext) -> Signal<[Int64: String], NoError> {
        return sharedContext.activeAccountsWithInfo
        |> take(1)
        |> map { _, accounts -> [Int64: String] in
            var result: [Int64: String] = [:]
            for info in accounts {
                let title = info.peer.debugDisplayTitle
                if !title.isEmpty {
                    result[info.account.peerId.toInt64()] = title
                }
            }
            return result
        }
    }

    // MARK: Reading

    /// The Keychain copy with the signed-in state taken from the account records, newest backup first.
    static func sessions(records: [WGAccountRecord]) -> Signal<[WGSessionBackupSession], NoError> {
        let loggedIn = Set(WGSessionBackupRules.backupCandidates(records).map { $0.peerId })
        return Signal { subscriber in
            WGSessionBackupService.queue.async {
                let sessions = WGSessionBackupKeychain.loadAll().map { entry in
                    return WGSessionBackupSession(peerId: entry.peerId, name: entry.backup.name, date: entry.backup.date, isLoggedIn: loggedIn.contains(entry.peerId))
                }.sorted(by: { $0.date > $1.date })
                subscriber.putNext(sessions)
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
        |> deliverOnMainQueue
    }

    // MARK: Backup

    /// Saves every signed-in account; `completion` gets the number saved and whether all writes worked.
    static func backupAll(sharedContext: SharedAccountContext, completion: @escaping (Int, Bool) -> Void) {
        let _ = (combineLatest(WGSessionBackupService.accountRecords(sharedContext.accountManager), WGSessionBackupService.accountNames(sharedContext))
        |> deliverOn(WGSessionBackupService.queue)
        |> map { records, names -> (Int, Bool) in
            let existing = Dictionary(WGSessionBackupKeychain.loadAll().map { ($0.peerId, $0.backup) }, uniquingKeysWith: { first, _ in first })
            var saved = 0
            var allWritten = true
            for candidate in WGSessionBackupRules.backupCandidates(records) {
                let name = names[candidate.peerId] ?? existing[candidate.peerId]?.name
                if WGSessionBackupKeychain.save(peerId: candidate.peerId, backup: WGSessionBackup(name: name, date: Date(), accountRecord: candidate.record)) {
                    saved += 1
                } else {
                    allWritten = false
                }
            }
            WGLog.info("sessionBackup", "manual backup: \(saved) saved")
            return (saved, allWritten)
        }
        |> deliverOnMainQueue).start(next: { saved, allWritten in
            completion(saved, allWritten)
        })
    }

    /// Auto backup: writes an account only when it has no copy yet or its backup data changed.
    static func autoBackup(records: [WGAccountRecord], sharedContext: SharedAccountContext) {
        let candidates = WGSessionBackupRules.backupCandidates(records)
        if candidates.isEmpty {
            return
        }
        let _ = (WGSessionBackupService.accountNames(sharedContext)
        |> deliverOn(WGSessionBackupService.queue)).start(next: { names in
            let existing = Dictionary(WGSessionBackupKeychain.loadAll().map { ($0.peerId, $0.backup) }, uniquingKeysWith: { first, _ in first })
            var written = 0
            for candidate in candidates {
                let stored = existing[candidate.peerId]
                let name = names[candidate.peerId] ?? stored?.name
                if let stored, stored.name == name, WGSessionBackupRules.backupData(of: stored.accountRecord) == WGSessionBackupRules.backupData(of: candidate.record) {
                    continue
                }
                if WGSessionBackupKeychain.save(peerId: candidate.peerId, backup: WGSessionBackup(name: name, date: Date(), accountRecord: candidate.record)) {
                    written += 1
                }
            }
            if written != 0 {
                WGLog.info("sessionBackup", "auto backup: \(written) written")
            }
        })
    }

    // MARK: Restore

    /// Creates a record for every backup whose user is not among the app's records; `completion`
    /// gets the number restored. The app picks the new records up by itself (SharedAccountContext
    /// observes the account manager), no restart.
    static func restore(accountManager: AccountManager<TelegramAccountManagerTypes>, completion: @escaping (Int) -> Void) {
        let _ = (Signal<[WGSessionBackupKeychain.Entry], NoError> { subscriber in
            WGSessionBackupService.queue.async {
                subscriber.putNext(WGSessionBackupKeychain.loadAll())
                subscriber.putCompletion()
            }
            return EmptyDisposable
        }
        |> mapToSignal { entries -> Signal<Int, NoError> in
            return accountManager.transaction { transaction -> Int in
                var present = Set<Int64>()
                for record in transaction.getRecords() {
                    if let peerId = WGSessionBackupRules.peerId(of: record) {
                        present.insert(peerId)
                    }
                }
                var restored = 0
                for entry in entries.sorted(by: { $0.backup.date < $1.backup.date }) {
                    let record = entry.backup.accountRecord
                    guard let peerId = WGSessionBackupRules.peerId(of: record), !present.contains(peerId) else {
                        continue
                    }
                    let sortOrder = WGSessionBackupRules.nextSortOrder(transaction.getRecords())
                    let _ = transaction.createRecord(WGSessionBackupRules.restoredAttributes(of: record, sortOrder: sortOrder))
                    present.insert(peerId)
                    restored += 1
                }
                return restored
            }
        }
        |> deliverOnMainQueue).start(next: { restored in
            WGLog.info("sessionBackup", "restored \(restored)")
            completion(restored)
        })
    }

    // MARK: Deleting

    static func delete(peerId: Int64, completion: @escaping () -> Void) {
        WGSessionBackupService.queue.async {
            WGSessionBackupKeychain.delete(peerId: peerId)
            Queue.mainQueue().async(completion)
        }
    }

    static func deleteAll(completion: @escaping () -> Void) {
        WGSessionBackupService.queue.async {
            WGSessionBackupKeychain.deleteAll()
            Queue.mainQueue().async(completion)
        }
    }

    /// Removes the signed-in account of `peerId` from the app. The server session stays alive; a copy
    /// is written to the Keychain first, and nothing is removed if that fails.
    static func removeFromApp(sharedContext: SharedAccountContext, peerId: Int64, completion: @escaping (Bool) -> Void) {
        let accountManager = sharedContext.accountManager
        let _ = (combineLatest(WGSessionBackupService.accountRecords(accountManager), WGSessionBackupService.accountNames(sharedContext))
        |> deliverOn(WGSessionBackupService.queue)
        |> mapToSignal { records, names -> Signal<Bool, NoError> in
            guard let candidate = WGSessionBackupRules.backupCandidates(records).first(where: { $0.peerId == peerId }) else {
                return .single(false)
            }
            let storedName = WGSessionBackupKeychain.loadAll().first(where: { $0.peerId == peerId })?.backup.name
            guard WGSessionBackupKeychain.save(peerId: peerId, backup: WGSessionBackup(name: names[peerId] ?? storedName, date: Date(), accountRecord: candidate.record)) else {
                return .single(false)
            }
            let recordId = candidate.record.id
            return accountManager.transaction { transaction -> Bool in
                transaction.updateRecord(recordId, { _ in
                    return nil
                })
                return true
            }
        }
        |> deliverOnMainQueue).start(next: { removed in
            completion(removed)
        })
    }
}
