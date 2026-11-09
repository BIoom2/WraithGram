import Foundation

/// Before the rename to Wraithgram every directory of ours was called `ghostgram` (in the app group,
/// in each account's folder, in Application Support and Caches). `directory(in:)` returns
/// `<parent>/wraithgram` and, the first time it sees a parent, moves `<parent>/ghostgram` there if
/// only the old one exists. The move is a rename, so it is atomic and cheap, and whichever process
/// gets there first (the app or an extension) does it.
public enum WGLegacyPaths {
    public static let name = "wraithgram"
    public static let legacyName = "ghostgram"

    private static let lock = WGUnfairLock()
    private static var checkedParents = Set<String>()

    /// `<parent>/wraithgram`. Does not create it.
    public static func directory(in parent: String) -> String {
        let path = (parent as NSString).appendingPathComponent(WGLegacyPaths.name)
        let isNew = WGLegacyPaths.lock.withLock { () -> Bool in
            return WGLegacyPaths.checkedParents.insert(parent).inserted
        }
        if isNew {
            let legacyPath = (parent as NSString).appendingPathComponent(WGLegacyPaths.legacyName)
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: legacyPath) && !fileManager.fileExists(atPath: path) {
                try? fileManager.moveItem(atPath: legacyPath, toPath: path)
            }
        }
        return path
    }

    /// `<parent>/wraithgram` as a file URL.
    public static func directory(in parent: URL) -> URL {
        return URL(fileURLWithPath: WGLegacyPaths.directory(in: parent.path), isDirectory: true)
    }
}
