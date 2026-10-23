import AppKit
import SwiftUI
import CryptoKit
import UniformTypeIdentifiers
import ParadiseKit

final class AppModel: ObservableObject {
    @Published var games: [GameDescriptor] = []
    @Published var current: GameDescriptor?
    @Published var frame: CGImage?
    @Published var paused = false
    var confirmationVisible = false
    @Published var settingsVisible = false
    @Published var errorMessage: String?
    @Published var bindingMessage: String?
    @Published var recording: (player: Int, button: GameButton)?
    @Published var bindings: InputBindings
    @Published var volume: Double { didSet { UserDefaults.standard.set(volume, forKey:"volume"); updateVolume() } }
    @Published var muted: Bool { didSet { UserDefaults.standard.set(muted, forKey:"muted"); updateVolume() } }
    let resources: URL
    let support: URL
    private var runner: GameRunner?
    private var timer: Timer?
    private var lastTime = 0.0
    private var accumulator = 0.0
    private var pressed = Set<UInt16>()
    private var keyMonitor: Any?
    private var observers: [NSObjectProtocol] = []
    private let factories: [String: () -> GameRunner] = ["nes": { NESRunner() }]
    private var keysURL: URL { support.appendingPathComponent("keys.json") }
    private var userGamesURL: URL { support.appendingPathComponent("Games") }

    init() {
        resources = Bundle.main.resourceURL?.appendingPathComponent("Games").deletingLastPathComponent() ?? URL(fileURLWithPath:FileManager.default.currentDirectoryPath).appendingPathComponent("Resources")
        support = FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("ParadiseGame")
        bindings = InputBindings.load(from: support.appendingPathComponent("keys.json"))
        volume = UserDefaults.standard.object(forKey:"volume") == nil ? 0.7 : min(1,max(0,UserDefaults.standard.double(forKey:"volume")))
        muted = UserDefaults.standard.bool(forKey:"muted")
        do {
            try FileManager.default.createDirectory(at: support, withIntermediateDirectories:true)
            try FileManager.default.createDirectory(at: userGamesURL, withIntermediateDirectories:true)
            games = try GameCatalog.load(url:resources.appendingPathComponent("Games/catalog.json"))
            let userCatalog=userGamesURL.appendingPathComponent("catalog.json")
            if FileManager.default.fileExists(atPath:userCatalog.path) { games += try GameCatalog.load(url:userCatalog) }
            games = try GameCatalog.validate(games)
        } catch { errorMessage = error.localizedDescription }
        keyMonitor=NSEvent.addLocalMonitorForEvents(matching:[.keyDown,.keyUp]) { [weak self] event in
            guard let self else { return event }
            return self.handle(event)
        }
        for name in [NSApplication.didResignActiveNotification, NSWindow.didResignKeyNotification] {
            observers.append(NotificationCenter.default.addObserver(forName:name,object:nil,queue:.main) { [weak self] _ in
                self?.pressed.removeAll(); self?.recording=nil
                if self?.current != nil { self?.setPaused(true) }
            })
        }
    }
    func launch(_ game: GameDescriptor) {
        stop()
        do {
            guard let factory=factories[game.runner] else {throw GameError("暂未安装此游戏的运行器")}
            let bundled=resources.appendingPathComponent("Games/\(game.file)")
            let rom=FileManager.default.fileExists(atPath:bundled.path) ? bundled : userGamesURL.appendingPathComponent(game.file)
            let data=try Data(contentsOf:rom)
            try ROMValidator.validate(data)
            if let expected=game.sha256 {
                let digest=SHA256.hash(data:data).map { String(format:"%02x",$0) }.joined()
                guard digest==expected else {throw GameError("游戏资源校验失败，请重新导入正确版本")}
            }
            let instance=factory()
            let core=resources.appendingPathComponent("Cores/nestopia_libretro.dylib")
            try instance.load(core:core,rom:rom,saves:support)
            runner=instance;current=game;paused=false;updateVolume();resetClock()
            timer=Timer(timeInterval:1.0/240,repeats:true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(timer!,forMode:.common)
        } catch { errorMessage=error.localizedDescription }
    }
    private func tick() {
        guard let runner, !paused else {return}
        let now=ProcessInfo.processInfo.systemUptime
        accumulator += min(now-lastTime,0.1);lastTime=now
        let step=1.0/runner.fps
        var count=0
        while accumulator>=step && count<5 {
            runner.step(inputs:bindings.masks(pressed:pressed));accumulator-=step;count+=1
        }
        if count==5 {accumulator=min(accumulator,step)}
        if count>0 {frame=runner.image}
    }
    private func resetClock() { lastTime=ProcessInfo.processInfo.systemUptime;accumulator=0 }
    func setPaused(_ value: Bool) {
        guard current != nil else {return}
        pressed.removeAll();paused=value
        if value {runner?.pause()} else {resetClock();runner?.resume()}
    }
    func reset() { confirmationVisible=false; pressed.removeAll();runner?.reset();paused=false;resetClock() }
    func stop() { confirmationVisible=false; timer?.invalidate();timer=nil;runner?.stop();runner=nil;current=nil;frame=nil;pressed.removeAll();paused=false }
    func showSettings() { if current != nil {setPaused(true)};recording=nil;bindingMessage=nil;settingsVisible=true }
    func closeSettings() { recording=nil;settingsVisible=false }
    private func updateVolume() { runner?.volume=muted ? 0 : Float(volume) }
    func restoreBindings() {
        do {try InputBindings.defaults.save(to:keysURL);bindings = .defaults;recording=nil;bindingMessage="已恢复默认按键"}
        catch {bindingMessage="保存失败：\(error.localizedDescription)"}
    }
    func beginRecording(player: Int, button: GameButton) {recording=(player,button);bindingMessage="请按下新按键，Esc 取消"}
    private func handle(_ event: NSEvent) -> NSEvent? {
        if let capture=recording {
            guard event.type == .keyDown else {return nil}
            if event.keyCode==53 {recording=nil;bindingMessage=nil;return nil}
            guard !event.isARepeat, event.modifierFlags.intersection([.command,.control,.option,.shift]).isEmpty else {return nil}
            do {
                var updated=bindings
                try updated.assign(player:capture.player,button:capture.button,key:event.keyCode)
                try updated.save(to:keysURL);bindings=updated;recording=nil;bindingMessage="按键已保存"
            } catch {bindingMessage=error.localizedDescription}
            return nil
        }
        guard current != nil, !settingsVisible, !confirmationVisible, errorMessage == nil else {return event}
        if event.type == .keyUp {pressed.remove(event.keyCode);return nil}
        if event.modifierFlags.contains(.command) {pressed.removeAll();return event}
        if event.keyCode==53 {if !event.isARepeat {setPaused(!paused)};return nil}
        if !paused {pressed.insert(event.keyCode)}
        return nil
    }
    func importGame() {
        setPaused(true)
        let panel=NSOpenPanel();panel.allowedContentTypes=[UTType(filenameExtension:"nes") ?? .data];panel.allowsMultipleSelection=false;panel.message="添加本地 FC 游戏到游戏大厅"
        guard panel.runModal() == .OK,let url=panel.url else {return}
        do {
            let data=try Data(contentsOf:url);try ROMValidator.validate(data)
            let digest=SHA256.hash(data:data).map {String(format:"%02x",$0)}.joined()
            guard !games.contains(where:{$0.sha256==digest}) else {throw GameError("这个游戏已经在大厅里了")}
            let id="local-"+digest.prefix(16), file=id+".nes"
            let game=GameDescriptor(id:id,title:url.deletingPathExtension().lastPathComponent,subtitle:"本地 FC 游戏",runner:"nes",file:file,sha256:digest)
            let catalog=userGamesURL.appendingPathComponent("catalog.json")
            var local=FileManager.default.fileExists(atPath:catalog.path) ? try GameCatalog.load(url:catalog) : []
            local.append(game);_ = try GameCatalog.validate(games+[game])
            try data.write(to:userGamesURL.appendingPathComponent(file),options:.atomic)
            try JSONEncoder().encode(local).write(to:catalog,options:.atomic)
            games.append(game)
        } catch {errorMessage=error.localizedDescription}
    }
    deinit {timer?.invalidate();if let keyMonitor {NSEvent.removeMonitor(keyMonitor)};observers.forEach(NotificationCenter.default.removeObserver)}
}
