import Foundation
public struct GameDescriptor: Codable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let runner: String
    public let file: String
    public let sha256: String?
    public let preview: String?
    public let players: String?
    public let instructions: String?
    public let actionA: String?
    public let actionB: String?
    public init(id: String, title: String, subtitle: String, runner: String, file: String, sha256: String?, preview: String? = nil, players: String? = nil, instructions: String? = nil, actionA: String? = nil, actionB: String? = nil) {
        self.id=id; self.title=title; self.subtitle=subtitle; self.runner=runner; self.file=file; self.sha256=sha256
        self.preview=preview; self.players=players; self.instructions=instructions; self.actionA=actionA; self.actionB=actionB
    }
}
public enum GameCatalog {
    public static func load(url: URL) throws -> [GameDescriptor] {
        try validate(JSONDecoder().decode([GameDescriptor].self, from: Data(contentsOf: url)))
    }
    public static func validate(_ games: [GameDescriptor]) throws -> [GameDescriptor] {
        var ids = Set<String>()
        for game in games {
            guard !game.id.isEmpty, ids.insert(game.id).inserted else { throw GameError("游戏目录存在重复或空的标识") }
            guard !game.file.isEmpty, !game.file.contains("/"), !game.file.contains("\\"), game.file != ".", game.file != ".." else { throw GameError("游戏资源路径无效") }
            if let preview=game.preview {
                guard !preview.isEmpty, !preview.contains("/"), !preview.contains("\\"), preview != ".", preview != ".." else { throw GameError("游戏预览路径无效") }
            }
            guard !game.title.isEmpty, !game.runner.isEmpty else { throw GameError("游戏目录缺少名称或运行器") }
        }
        return games
    }
}
