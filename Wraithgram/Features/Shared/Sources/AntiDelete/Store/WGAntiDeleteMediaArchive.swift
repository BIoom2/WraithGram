import Darwin
import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore
import WGCore

/// «Сохранять медиа удалённых»: a deleted message keeps only a reference to its media, and the
/// cache cleanup would eventually delete the file, which can not be downloaded again once the
/// server has deleted the message. The archive keeps a hard link (no extra space while the cache
/// still has the file) per message and resource in `<account>/wraithgram/antiDelete/media`, and
/// links it back into the media cache when the chat with the message is opened.
/// Never for secret chats: their media must not outlive the chat outside the media box.
public enum WGAntiDeleteMediaArchive {
    public static let maximumFileSize: Int64 = 100 * 1024 * 1024

    static func directory(basePath: String) -> String {
        return WGLegacyPaths.directory(in: basePath) + "/antiDelete/media"
    }

    private static func sanitized(_ string: String) -> String {
        var result = ""
        for scalar in string.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) || scalar == "-" || scalar == "." {
                result.unicodeScalars.append(scalar)
            } else {
                result.append("_")
            }
        }
        return result
    }

    /// The part of a file name that identifies the message: four numbers, then `_` and the resource.
    private static func messagePrefix(_ messageId: MessageId) -> String {
        let peer = messageId.peerId.wgKey
        return "\(peer.namespace)_\(peer.id)_\(messageId.namespace)_\(messageId.id)"
    }

    static func archivedPath(basePath: String, messageId: MessageId, resourceId: MediaResourceId) -> String {
        let name = WGAntiDeleteMediaArchive.messagePrefix(messageId) + "_" + WGAntiDeleteMediaArchive.sanitized(resourceId.stringRepresentation)
        return WGAntiDeleteMediaArchive.directory(basePath: basePath) + "/" + name
    }

    /// The resources worth keeping: the largest photo, the file itself (bounded size).
    static func resources(of message: Message) -> [(resource: TelegramMediaResource, media: Media, contentType: MediaResourceUserContentType)] {
        if message.id.peerId.namespace == Namespaces.Peer.SecretChat {
            return []
        }
        var result: [(resource: TelegramMediaResource, media: Media, contentType: MediaResourceUserContentType)] = []
        for media in message.media {
            if let image = media as? TelegramMediaImage, let representation = largestImageRepresentation(image.representations) {
                result.append((representation.resource, image, .image))
            } else if let file = media as? TelegramMediaFile {
                if let size = file.size, size > WGAntiDeleteMediaArchive.maximumFileSize {
                    continue
                }
                let contentType: MediaResourceUserContentType
                if file.isInstantVideo {
                    contentType = .audioVideoMessage
                } else if file.isVideo {
                    contentType = .video
                } else if file.isVoice || file.isMusic {
                    contentType = .audio
                } else if file.isSticker || file.isAnimatedSticker {
                    contentType = .sticker
                } else {
                    contentType = .file
                }
                result.append((file.resource, file, contentType))
            }
        }
        return result
    }

    private static func ensureDirectory(_ path: String) {
        if FileManager.default.fileExists(atPath: path) {
            return
        }
        let _ = try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        var url = URL(fileURLWithPath: path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)
    }

    private static func link(from source: String, to destination: String) {
        if FileManager.default.fileExists(atPath: destination) {
            return
        }
        if Darwin.link(source, destination) != 0 {
            let _ = try? FileManager.default.copyItem(atPath: source, toPath: destination)
        }
    }

    /// After new deleted entries were indexed (anti-delete queue).
    static func archive(postbox: Postbox, basePath: String, peerId: PeerId, entries: [WGAntiDeleteLogEntry]) {
        if !WGAntiDeleteSettings.keepMedia.value || peerId.namespace == Namespaces.Peer.SecretChat {
            return
        }
        let ids = entries.filter { !$0.isArchiveOnly }.map { MessageId(peerId: peerId, namespace: $0.namespace, id: $0.id) }
        if ids.isEmpty {
            return
        }
        let _ = (postbox.transaction { transaction -> [Message] in
            return ids.compactMap { transaction.getMessage($0) }
        }
        |> deliverOn(WGAntiDeleteAccounts.shared.queue)).start(next: { messages in
            let directory = WGAntiDeleteMediaArchive.directory(basePath: basePath)
            WGAntiDeleteMediaArchive.ensureDirectory(directory)
            for message in messages {
                for item in WGAntiDeleteMediaArchive.resources(of: message) {
                    let destination = WGAntiDeleteMediaArchive.archivedPath(basePath: basePath, messageId: message.id, resourceId: item.resource.id)
                    if let path = postbox.mediaBox.completedResourcePath(id: item.resource.id) {
                        WGAntiDeleteMediaArchive.link(from: path, to: destination)
                        continue
                    }
                    // Not downloaded yet: try now, while the file reference may still be valid.
                    let reference = AnyMediaReference.message(message: MessageReference(message), media: item.media).resourceReference(item.resource)
                    let _ = (fetchedMediaResource(mediaBox: postbox.mediaBox, userLocation: .peer(peerId), userContentType: item.contentType, reference: reference)
                    |> deliverOn(WGAntiDeleteAccounts.shared.queue)).start(error: { _ in
                    }, completed: {
                        if let path = postbox.mediaBox.completedResourcePath(id: item.resource.id) {
                            WGAntiDeleteMediaArchive.link(from: path, to: destination)
                            WGAntiDeleteMediaArchive.scheduleLimitCheck(basePath: basePath)
                        }
                    })
                }
            }
            WGAntiDeleteMediaArchive.scheduleLimitCheck(basePath: basePath)
        })
    }

    /// Puts archived files back into the media cache for kept messages of a chat whose cached
    /// copy is gone. Returns (async) the messages that got something back, to redraw them.
    public static func restore(postbox: Postbox, basePath: String, peerId: PeerId, completion: @escaping ([MessageId]) -> Void) {
        if peerId.namespace == Namespaces.Peer.SecretChat {
            completion([])
            return
        }
        let directory = WGAntiDeleteMediaArchive.directory(basePath: basePath)
        let _ = (postbox.transaction { transaction -> [Message] in
            let log = WGAntiDeleteIndexStore.readLog(transaction, kind: .deleted, peerId: peerId)
            return log.entries.filter { !$0.isArchiveOnly }.compactMap { transaction.getMessage(MessageId(peerId: peerId, namespace: $0.namespace, id: $0.id)) }
        }
        |> deliverOn(WGAntiDeleteAccounts.shared.queue)).start(next: { messages in
            if !FileManager.default.fileExists(atPath: directory) {
                completion([])
                return
            }
            var restored: [MessageId] = []
            for message in messages {
                var didRestore = false
                for item in WGAntiDeleteMediaArchive.resources(of: message) {
                    if postbox.mediaBox.completedResourcePath(id: item.resource.id) != nil {
                        continue
                    }
                    let archived = WGAntiDeleteMediaArchive.archivedPath(basePath: basePath, messageId: message.id, resourceId: item.resource.id)
                    if FileManager.default.fileExists(atPath: archived) {
                        WGAntiDeleteMediaArchive.link(from: archived, to: postbox.mediaBox.resourcePath(item.resource))
                        didRestore = true
                    }
                }
                if didRestore {
                    restored.append(message.id)
                }
            }
            completion(restored)
        })
    }

    /// Removes the archived files of messages that are gone for real (anti-delete queue). Found by the
    /// message part of the file name, so it does not need the message (it may be deleted already).
    /// The four leading numbers are followed by `_`, so message 1 never matches message 12.
    static func remove(basePath: String, messageIds: [MessageId]) {
        if messageIds.isEmpty {
            return
        }
        let directory = WGAntiDeleteMediaArchive.directory(basePath: basePath)
        guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return
        }
        let prefixes = Set(messageIds.map { WGAntiDeleteMediaArchive.messagePrefix($0) })
        for name in names {
            let parts = name.split(separator: "_", maxSplits: 4, omittingEmptySubsequences: false)
            if parts.count == 5 && prefixes.contains(parts[0 ..< 4].joined(separator: "_")) {
                unlink(directory + "/" + name)
            }
        }
    }

    /// Everything of an account (history cleared).
    static func removeAll(basePath: String) {
        let _ = try? FileManager.default.removeItem(atPath: WGAntiDeleteMediaArchive.directory(basePath: basePath))
    }

    // MARK: Size limit

    private static let limitLock = NSLock()
    private static var limitScheduled = Set<String>()

    /// Checks the size soon (coalesced: a burst of linked files is one directory scan). Anti-delete queue.
    static func scheduleLimitCheck(basePath: String) {
        WGAntiDeleteMediaArchive.limitLock.lock()
        let isNew = WGAntiDeleteMediaArchive.limitScheduled.insert(basePath).inserted
        WGAntiDeleteMediaArchive.limitLock.unlock()
        if !isNew {
            return
        }
        WGAntiDeleteAccounts.shared.queue.after(3.0, {
            WGAntiDeleteMediaArchive.limitLock.lock()
            WGAntiDeleteMediaArchive.limitScheduled.remove(basePath)
            WGAntiDeleteMediaArchive.limitLock.unlock()
            WGAntiDeleteMediaArchive.enforceLimit(basePath: basePath)
        })
    }

    /// Over the limit: the oldest files go first until the archive fits (media only, the index entries
    /// stay). The age is the modification time of the file, which a hard link shares with the cache
    /// file it was made from (roughly the time of the download). Anti-delete queue.
    static func enforceLimit(basePath: String) {
        guard let limit = WGAntiDeleteArchiveLimit(settingValue: WGAntiDeleteSettings.archiveLimit.value).maximumBytes else {
            return
        }
        let directory = WGAntiDeleteMediaArchive.directory(basePath: basePath)
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: directory), includingPropertiesForKeys: keys, options: []) else {
            return
        }
        var files: [(url: URL, size: Int64, date: Date)] = []
        var total: Int64 = 0
        for url in urls {
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true else {
                continue
            }
            let size = Int64(values.fileSize ?? 0)
            files.append((url, size, values.contentModificationDate ?? Date.distantPast))
            total += size
        }
        if total <= limit {
            return
        }
        files.sort(by: { $0.date < $1.date })
        for file in files {
            if total <= limit {
                break
            }
            if unlink(file.url.path) == 0 {
                total -= file.size
            }
        }
    }
}
