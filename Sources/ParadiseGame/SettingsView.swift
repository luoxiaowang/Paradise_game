import SwiftUI
import ParadiseKit
struct SettingsView: View {
    @ObservedObject var model:AppModel
    var body:some View {
        VStack(alignment:.leading,spacing:20) {
            HStack {VStack(alignment:.leading,spacing:6){Text("按键与声音").font(.title2.bold());Text("两位玩家可以共用键盘，设置会自动保存。").font(.caption).foregroundStyle(.secondary)};Spacer();Button("完成"){model.closeSettings()}.keyboardShortcut(.defaultAction)}
            Divider()
            HStack(alignment:.top,spacing:30) {
                ForEach(0..<2,id:\.self) {p in
                    VStack(alignment:.leading,spacing:10) {
                        Text("玩家 \(p+1)").font(.headline).foregroundStyle(p==0 ? paradiseAccent : .cyan).padding(.bottom,4)
                        ForEach(GameButton.allCases,id:\.self) {button in
                            HStack {Text(button.title).font(.subheadline);Spacer();Button {model.beginRecording(player:p,button:button)} label:{Text(isRecording(p,button) ? "请按键…" : KeyNames.name(model.bindings.key(player:p,button:button))).frame(width:125)}.tint(isRecording(p,button) ? paradiseAccent : .gray)}
                        }
                    }.frame(maxWidth:.infinity)
                }
            }
            Text(model.bindingMessage ?? "点击按键即可修改；不允许两项操作使用同一按键，Esc 可取消录入。")
                .font(.caption).foregroundStyle(model.recording == nil ? .secondary : paradiseAccent).frame(height:32,alignment:.leading)
            Divider()
            HStack {Label("游戏音量",systemImage:"speaker.wave.2");Slider(value:$model.volume,in:0...1).frame(width:220);Text("\(Int(model.volume*100))%").monospacedDigit().frame(width:40);Spacer();Toggle("静音",isOn:$model.muted).toggleStyle(.switch)}
            HStack {Button("恢复默认按键"){model.restoreBindings()};Spacer();Text("Esc 保留为应用暂停键").font(.caption).foregroundStyle(.secondary)}
        }.padding(28).frame(width:660).background(paradiseBackground).preferredColorScheme(.dark)
    }
    private func isRecording(_ p:Int,_ b:GameButton)->Bool {model.recording?.player==p && model.recording?.button==b}
}
