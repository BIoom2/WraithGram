import Foundation

/// «Размер архива медиа»: the media archive of kept deleted messages is bounded; when it grows over
/// the limit, the oldest archived files go first (the text entries stay).
public enum WGAntiDeleteArchiveLimit: String, CaseIterable {
    case mb500
    case gb1
    case gb2
    case gb5
    case unlimited

    public static let `default`: WGAntiDeleteArchiveLimit = .gb2

    public init(settingValue: String) {
        self = WGAntiDeleteArchiveLimit(rawValue: settingValue) ?? WGAntiDeleteArchiveLimit.default
    }

    /// Maximum size of the archive in bytes; nil = unlimited.
    public var maximumBytes: Int64? {
        let megabyte: Int64 = 1024 * 1024
        switch self {
        case .mb500:
            return 500 * megabyte
        case .gb1:
            return 1024 * megabyte
        case .gb2:
            return 2 * 1024 * megabyte
        case .gb5:
            return 5 * 1024 * megabyte
        case .unlimited:
            return nil
        }
    }
}
