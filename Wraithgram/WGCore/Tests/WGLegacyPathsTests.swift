import XCTest
import Foundation

final class WGLegacyPathsTests: XCTestCase {
    private var parent: String!

    override func setUp() {
        super.setUp()
        self.parent = (NSTemporaryDirectory() as NSString).appendingPathComponent("wg-legacy-paths-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(atPath: self.parent, withIntermediateDirectories: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: self.parent)
        super.tearDown()
    }

    private func write(_ text: String, to relativePath: String) {
        let path = (self.parent as NSString).appendingPathComponent(relativePath)
        try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
        try? text.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func read(_ relativePath: String) -> String? {
        return try? String(contentsOfFile: (self.parent as NSString).appendingPathComponent(relativePath), encoding: .utf8)
    }

    func testMovesTheDirectoryFromBeforeTheRename() {
        self.write("old", to: "ghostgram/settings.json")
        let directory = WGLegacyPaths.directory(in: self.parent)
        XCTAssertEqual(directory, (self.parent as NSString).appendingPathComponent("wraithgram"))
        XCTAssertEqual(self.read("wraithgram/settings.json"), "old")
        XCTAssertFalse(FileManager.default.fileExists(atPath: (self.parent as NSString).appendingPathComponent("ghostgram")))
    }

    func testKeepsTheCurrentDirectoryWhenBothExist() {
        self.write("old", to: "ghostgram/settings.json")
        self.write("new", to: "wraithgram/settings.json")
        let _ = WGLegacyPaths.directory(in: self.parent)
        XCTAssertEqual(self.read("wraithgram/settings.json"), "new")
        XCTAssertEqual(self.read("ghostgram/settings.json"), "old")
    }

    func testDoesNotCreateAnythingWithoutTheOldDirectory() {
        let directory = WGLegacyPaths.directory(in: self.parent)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory))
    }
}
