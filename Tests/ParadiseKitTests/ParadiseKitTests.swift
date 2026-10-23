import Foundation
import ParadiseKit

final class ParadiseKitTests {
    func testGameMetadata() throws {
        let old = Data(#"[{"id":"old","title":"旧游戏","subtitle":"","runner":"nes","file":"old.nes"}]"#.utf8)
        let game = try JSONDecoder().decode([GameDescriptor].self, from: old)[0]
        XCTAssertEqual(game.preview, nil)
        let mario = GameDescriptor(id:"mario", title:"超级玛丽", subtitle:"", runner:"nes", file:"mario.nes", sha256:nil, preview:"mario-preview.png", players:"1–2 人 · 轮流", instructions:"开始游戏", actionA:"跳跃", actionB:"加速 / 火球")
        XCTAssertEqual(try JSONDecoder().decode(GameDescriptor.self, from: JSONEncoder().encode(mario)), mario)
        let bad = GameDescriptor(id:"bad", title:"测试", subtitle:"", runner:"nes", file:"ok.nes", sha256:nil, preview:"../bad.png")
        XCTAssertThrowsError(try GameCatalog.validate([bad]))
    }
    func testTruncatedROMRejected() throws {
        var rom = Data([0x4e,0x45,0x53,0x1a,2,1,0,0,0,0,0,0,0,0,0,0])
        XCTAssertThrowsError(try ROMValidator.validate(rom))
        rom.append(Data(repeating: 0, count: 40960))
        XCTAssertNoThrow(try ROMValidator.validate(rom))
        rom[0] = 0
        XCTAssertThrowsError(try ROMValidator.validate(rom))
    }
    func testUnsupportedNES2Rejected() {
        var rom = Data(repeating: 0, count: 40976)
        rom.replaceSubrange(0..<8, with: [0x4e,0x45,0x53,0x1a,2,1,0,8])
        XCTAssertThrowsError(try ROMValidator.validate(rom))
    }
    func testTwoPlayersSimultaneousAndRelease() {
        let b = InputBindings.defaults
        let masks = b.masks(pressed: [13,38,126,43])
        XCTAssertEqual(masks[0], (1 << 4) | (1 << 8))
        XCTAssertEqual(masks[1], (1 << 4) | (1 << 8))
        XCTAssertEqual(b.masks(pressed: []), [0,0])
    }
    func testConflictDoesNotMutateMapping() throws {
        var b = InputBindings.defaults
        XCTAssertThrowsError(try b.assign(player: 1, button: .a, key: 13))
        XCTAssertEqual(b.key(player: 1, button: .a), 43)
        try b.assign(player: 1, button: .a, key: 37)
        XCTAssertEqual(b.masks(pressed: [37]), [0, 1 << 8])
    }
    func testReservedKeysRejected() {
        var b = InputBindings.defaults
        XCTAssertThrowsError(try b.assign(player: 0, button: .a, key: 53))
    }
    func testSettingsRoundTripAndCorruptionRecovery() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("keys.json")
        var b = InputBindings.defaults
        try b.assign(player: 0, button: .a, key: 37)
        try b.save(to: file)
        XCTAssertEqual(InputBindings.load(from: file).key(player: 0, button: .a), 37)
        try Data("broken".utf8).write(to: file)
        XCTAssertEqual(InputBindings.load(from: file), .defaults)
    }
    func testCatalogRejectsDuplicateIDAndTraversal() throws {
        let game = GameDescriptor(id: "tank1990", title: "坦克大战", subtitle: "烟山版", runner: "nes", file: "tank1990.nes", sha256: nil)
        XCTAssertThrowsError(try GameCatalog.validate([game, game]))
        let bad = GameDescriptor(id: "bad", title: "测试", subtitle: "", runner: "nes", file: "../secret.nes", sha256: nil)
        XCTAssertThrowsError(try GameCatalog.validate([bad]))
        XCTAssertEqual(try GameCatalog.validate([game]).count, 1)
    }
}

func XCTAssertEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #filePath, line: UInt = #line) { precondition(a == b, "Expected \(b), got \(a) at \(file):\(line)") }
func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T) { do { _ = try expression(); fatalError("Expected rejection") } catch {} }
func XCTAssertNoThrow<T>(_ expression: @autoclosure () throws -> T) { do { _ = try expression() } catch { fatalError("Unexpected: \(error)") } }
@main struct TestMain {
    static func main() throws {
        let t = ParadiseKitTests()
        try t.testTruncatedROMRejected(); t.testUnsupportedNES2Rejected()
        t.testTwoPlayersSimultaneousAndRelease(); try t.testConflictDoesNotMutateMapping()
        t.testReservedKeysRejected(); try t.testSettingsRoundTripAndCorruptionRecovery()
        try t.testCatalogRejectsDuplicateIDAndTraversal()
        try t.testGameMetadata()
        print("PASS: 8 model tests")
    }
}
