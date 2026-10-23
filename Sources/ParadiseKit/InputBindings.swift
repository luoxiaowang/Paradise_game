import Foundation
public enum GameButton: String, Codable, CaseIterable {
    case up, down, left, right, a, b, start, select
    public var bit: UInt16 {
        let ids: [GameButton:Int] = [.b:0,.select:2,.start:3,.up:4,.down:5,.left:6,.right:7,.a:8]
        return 1 << ids[self]!
    }
    public var title: String {
        switch self { case .up:return "向上";case .down:return "向下";case .left:return "向左";case .right:return "向右";case .a:return "A 键";case .b:return "B 键";case .start:return "开始 / 暂停";case .select:return "选择" }
    }
}
public struct InputBindings: Codable, Equatable {
    private var players: [[String: UInt16]]
    public static let defaults = InputBindings(players: [
        ["up":13,"down":1,"left":0,"right":2,"a":38,"b":40,"start":36,"select":49],
        ["up":126,"down":125,"left":123,"right":124,"a":43,"b":47,"start":76,"select":82]
    ])
    public func key(player: Int, button: GameButton) -> UInt16 { players[player][button.rawValue]! }
    public mutating func assign(player: Int, button: GameButton, key: UInt16) throws {
        guard (0..<2).contains(player), key <= 126, ![53,54,55,56,57,58,59,60,61,62,63].contains(key) else { throw GameError("此按键由系统或应用保留，请选择其他按键") }
        for p in 0..<2 { for b in GameButton.allCases where !(p == player && b == button) {
            if self.key(player: p, button: b) == key { throw GameError("此按键已用于玩家\(p+1)的「\(b.title)」") }
        }}
        players[player][button.rawValue] = key
    }
    public func masks(pressed: Set<UInt16>) -> [UInt16] {
        (0..<2).map { p in GameButton.allCases.reduce(UInt16(0)) { $0 | (pressed.contains(key(player: p, button: $1)) ? $1.bit : 0) } }
    }
    public func save(to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(self).write(to: url, options: .atomic)
    }
    public static func load(from url: URL) -> InputBindings {
        guard let data = try? Data(contentsOf: url), let value = try? JSONDecoder().decode(Self.self, from: data), value.valid else { return .defaults }
        return value
    }
    private var valid: Bool {
        guard players.count == 2 else { return false }
        var seen = Set<UInt16>()
        for p in players { for b in GameButton.allCases {
            guard let key=p[b.rawValue], key<=126, ![53,54,55,56,57,58,59,60,61,62,63].contains(key), seen.insert(key).inserted else {return false}
        }}
        return true
    }
}
