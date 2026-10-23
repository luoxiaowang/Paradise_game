import Foundation
public struct GameError: LocalizedError {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}
public enum ROMValidator {
    public static func validate(_ data: Data) throws {
        guard data.count >= 16, data.count <= 32*1024*1024 else { throw GameError("游戏文件大小无效") }
        let b = [UInt8](data.prefix(16))
        guard Array(b[0..<4]) == [0x4e,0x45,0x53,0x1a], b[4] > 0 else { throw GameError("请选择有效的 .nes 游戏文件") }
        guard b[7] & 12 != 8 else { throw GameError("当前导入支持 iNES 格式，暂不支持 NES 2.0") }
        let expected = 16 + (b[6] & 4 != 0 ? 512 : 0) + Int(b[4])*16384 + Int(b[5])*8192
        guard expected == data.count else { throw GameError("游戏文件不完整或含有未支持的附加数据") }
    }
}
