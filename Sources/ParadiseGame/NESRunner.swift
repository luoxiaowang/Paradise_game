import Foundation
import CoreGraphics
import CoreBridge
import ParadiseKit

protocol GameRunner: AnyObject {
    var fps: Double { get }
    var image: CGImage? { get }
    var volume: Float { get set }
    func load(core: URL, rom: URL, saves: URL) throws
    func step(inputs: [UInt16])
    func pause()
    func resume()
    func reset()
    func stop()
}
final class NESRunner: GameRunner {
    private var audio = AudioOutput()
    private(set) var image: CGImage?
    private var active = false
    var fps: Double { pg_fps() }
    var volume: Float { get { audio.volume } set { audio.volume=newValue } }
    func load(core: URL, rom: URL, saves: URL) throws {
        try ROMValidator.validate(Data(contentsOf: rom))
        guard pg_open(core.path, rom.path, saves.path) else { throw GameError(String(cString: pg_error())) }
        active = true
        do { try audio.start(rate: pg_sample_rate()) } catch { stop(); throw GameError("音频设备启动失败：\(error.localizedDescription)") }
    }
    func step(inputs: [UInt16]) {
        guard active else { return }
        for p in 0..<2 { pg_set_input(UInt32(p), inputs[p]) }
        pg_run()
        if let samples = pg_audio() { audio.append(samples, frames: pg_audio_frames()) }
        let w=Int(pg_width()), h=Int(pg_height())
        guard w>0, h>0, let pixels=pg_video() else {return}
        let data = Data(bytes: pixels, count: w*h*4)
        guard let provider=CGDataProvider(data: data as CFData) else {return}
        image=CGImage(width:w,height:h,bitsPerComponent:8,bitsPerPixel:32,bytesPerRow:w*4,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:CGBitmapInfo(rawValue:CGImageAlphaInfo.premultipliedLast.rawValue),provider:provider,decode:nil,shouldInterpolate:false,intent:.defaultIntent)
    }
    func pause() { for p in 0..<2 {pg_set_input(UInt32(p),0)};audio.pause() }
    func resume() { audio.resume() }
    func reset() { audio.pause();pg_reset();audio.resume() }
    func stop() { audio.stop();if active {pg_close()};active=false;image=nil }
    deinit { stop() }
}
