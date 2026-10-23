import SwiftUI
import AppKit

struct PixelView: NSViewRepresentable {
    var image: CGImage?
    func makeNSView(context:Context)->PixelSurface {PixelSurface()}
    func updateNSView(_ view:PixelSurface,context:Context) {view.image=image;view.needsDisplay=true}
}
final class PixelSurface: NSView {
    var image: CGImage?
    override var isFlipped: Bool {false}
    override func draw(_ dirtyRect:NSRect) {
        NSColor.black.setFill();bounds.fill()
        guard let image,let ctx=NSGraphicsContext.current?.cgContext else {return}
        let scale=max(1,floor(min(bounds.width/CGFloat(image.width),bounds.height/CGFloat(image.height))))
        let w=CGFloat(image.width)*scale,h=CGFloat(image.height)*scale
        ctx.interpolationQuality = .none
        ctx.draw(image,in:CGRect(x:floor((bounds.width-w)/2),y:floor((bounds.height-h)/2),width:w,height:h))
    }
}
struct GameView: View {
    @ObservedObject var model: AppModel
    @State private var confirmReset=false
    @State private var confirmExit=false
    var body: some View {
        VStack(spacing:0) {
            HStack(spacing:16) {
                Button {model.setPaused(true);model.confirmationVisible=true;confirmExit=true} label:{Label("游戏大厅",systemImage:"chevron.left")}
                Rectangle().fill(.white.opacity(0.15)).frame(width:1,height:18)
                Text(model.current?.title ?? "").font(.headline)
                Text("原版运行").font(.caption2).foregroundStyle(paradiseAccent).padding(.horizontal,8).padding(.vertical,4).background(paradiseAccent.opacity(0.10)).clipShape(Capsule())
                Spacer()
                Button {model.setPaused(!model.paused)} label:{Label(model.paused ? "继续":"暂停",systemImage:model.paused ? "play.fill":"pause.fill")}
                Button {model.setPaused(true);model.confirmationVisible=true;confirmReset=true} label:{Image(systemName:"arrow.counterclockwise")}.help("重新启动游戏")
                Button {model.muted.toggle()} label:{Image(systemName:model.muted ? "speaker.slash.fill":"speaker.wave.2.fill")}.help(model.muted ? "开启声音":"静音")
                Button {model.showSettings()} label:{Image(systemName:"slider.horizontal.3")}.help("按键与声音")
                Button {NSApp.keyWindow?.toggleFullScreen(nil)} label:{Image(systemName:"arrow.up.left.and.arrow.down.right")}.help("全屏")
            }.buttonStyle(.plain).padding(.horizontal,22).frame(height:58)
            Divider().opacity(0.4)
            ZStack {
                PixelView(image:model.frame).frame(maxWidth:.infinity,maxHeight:.infinity)
                if model.paused {
                    Color.black.opacity(0.65)
                    VStack(spacing:16) {Image(systemName:"pause.circle").font(.system(size:38)).foregroundStyle(paradiseAccent);Text("游戏已暂停").font(.title2.bold());Text("切换窗口会自动暂停，进度仍保留").font(.caption).foregroundStyle(.secondary);Button("继续游戏") {model.setPaused(false)}.buttonStyle(.borderedProminent).tint(paradiseAccent).foregroundStyle(.black).controlSize(.large)}.padding(32).background(paradiseBackground).clipShape(RoundedRectangle(cornerRadius:16))
                }
            }
            Divider().opacity(0.4)
            VStack(spacing:7) {
                HStack(spacing:24) {keyHint(0);keyHint(1);Spacer();Text("Esc · 暂停 / 继续").foregroundStyle(.secondary)}
                HStack {Text(model.current?.instructions ?? "使用选择键切换菜单，开始键确认。").foregroundStyle(.secondary);Spacer()}
            }.font(.system(size:11)).padding(.horizontal,22).padding(.vertical,12)
        }
        .onChange(of:confirmReset) { _ in model.confirmationVisible=confirmReset || confirmExit }
        .onChange(of:confirmExit) { _ in model.confirmationVisible=confirmReset || confirmExit }
        .alert("重新开始游戏？",isPresented:$confirmReset) {Button("取消",role:.cancel){};Button("重新开始",role:.destructive){model.reset()}} message:{Text("将回到原版菜单，当前对局进度会丢失。")}
        .alert("返回游戏大厅？",isPresented:$confirmExit) {Button("取消",role:.cancel){};Button("返回大厅",role:.destructive){model.stop()}} message:{Text("当前对局将结束。")}
    }
    private func keyHint(_ p:Int)->some View {
        let b=model.bindings
        let directions=[b.key(player:p,button:.up),b.key(player:p,button:.left),b.key(player:p,button:.down),b.key(player:p,button:.right)].map(KeyNames.name).joined(separator:" ")
        let a=KeyNames.name(b.key(player:p,button:.a))+" "+(model.current?.actionA ?? "A")
        let actionB=KeyNames.name(b.key(player:p,button:.b))+" "+(model.current?.actionB ?? "B")
        let hint=directions+" · "+a+" · "+actionB
        return HStack(spacing:8){Text("玩家 \(p+1)").foregroundStyle(p==0 ? paradiseAccent : .cyan);Text(hint).foregroundStyle(.secondary)}
    }
}
