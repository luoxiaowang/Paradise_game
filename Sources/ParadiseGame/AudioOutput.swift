import AVFoundation

/// A bounded queue; pause/stop discards pending samples instead of playing old audio.
final class AudioOutput {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var format: AVAudioFormat?
    private var pending = 0
    private var generation = 0
    var volume: Float = 0.7 { didSet { player.volume = volume } }
    func start(rate: Double) throws {
        format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 2)
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try engine.start()
        player.volume = volume
        player.play()
    }
    func append(_ samples: UnsafePointer<Int16>, frames: Int) {
        guard frames > 0, pending < 6, let format,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
              let channels = buffer.floatChannelData else { return }
        buffer.frameLength = AVAudioFrameCount(frames)
        for i in 0..<frames {
            channels[0][i] = Float(samples[i*2]) / 32768
            channels[1][i] = Float(samples[i*2+1]) / 32768
        }
        pending += 1
        let token = generation
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self, self.generation == token else { return }
                self.pending = max(0, self.pending-1)
            }
        }
    }
    func pause() { generation += 1; player.stop(); pending = 0 }
    func resume() { if engine.isRunning { player.play() } }
    func stop() { pause(); engine.stop() }
}
