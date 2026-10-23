import SwiftUI
import ParadiseKit

let paradiseAccent = Color(red:0.78,green:0.94,blue:0.40)
let paradiseBackground = Color(red:0.055,green:0.065,blue:0.08)

struct RootView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Group { if model.current != nil { GameView(model:model) } else { LibraryView(model:model) } }
            .frame(minWidth:900,minHeight:680)
            .background(paradiseBackground)
            .preferredColorScheme(.dark)
            .sheet(isPresented:$model.settingsVisible,onDismiss:{model.recording=nil}) { SettingsView(model:model) }
            .alert("无法完成操作",isPresented:Binding(get:{model.errorMessage != nil},set:{if !$0 {model.errorMessage=nil}})) {
                Button("知道了",role:.cancel){model.errorMessage=nil}
            } message: {Text(model.errorMessage ?? "")}
    }
}
struct LibraryView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        HStack(spacing:0) {
            VStack(alignment:.leading,spacing:28) {
                HStack(spacing:10) {
                    Image(systemName:"gamecontroller.fill").font(.title2).foregroundStyle(paradiseAccent)
                    VStack(alignment:.leading,spacing:3) {Text("游戏乐园").font(.headline);Text("Paradise Game").font(.caption).foregroundStyle(.secondary)}
                }.padding(.top,28)
                HStack {Image(systemName:"square.grid.2x2.fill");Text("我的游戏");Spacer();Text("\(model.games.count)").foregroundStyle(paradiseAccent)}
                    .padding(12).background(paradiseAccent.opacity(0.10)).clipShape(RoundedRectangle(cornerRadius:10))
                Spacer()
                Button {model.showSettings()} label: {Label("按键与声音",systemImage:"slider.horizontal.3")}.buttonStyle(.plain)
                Text("经典游戏，随时开局。\n本地运行 · 无需联网").font(.caption).foregroundStyle(.secondary).lineSpacing(5)
            }.padding(.horizontal,22).padding(.bottom,28).frame(width:190).background(Color.white.opacity(0.025))
            Rectangle().fill(Color.white.opacity(0.07)).frame(width:1)
            ScrollView {
                VStack(alignment:.leading,spacing:26) {
                    HStack(alignment:.top) {
                        VStack(alignment:.leading,spacing:10) {Text("欢迎回到游戏乐园").font(.system(size:29,weight:.bold));Text("挑一款游戏，把快乐留给这一局。").foregroundStyle(.secondary)}
                        Spacer()
                        Button {model.importGame()} label:{Label("添加游戏",systemImage:"plus")}.controlSize(.large)
                    }
                    HStack {Text("游戏收藏").font(.headline);Text("\(model.games.count) 款").foregroundStyle(.secondary);Spacer();Text("本地游戏库").font(.caption).foregroundStyle(.secondary)}
                    LazyVGrid(columns:[GridItem(.adaptive(minimum:290,maximum:380),spacing:20)],alignment:.leading,spacing:20) {
                        ForEach(model.games) {game in
                            VStack(alignment:.leading,spacing:0) {
                                ZStack {
                                    Color.black
                                    if let preview=game.preview,let image=NSImage(contentsOf:model.resources.appendingPathComponent(preview)) {
                                        Image(nsImage:image).resizable().interpolation(.none).scaledToFit().padding(18)
                                    } else {Image(systemName:"gamecontroller").font(.system(size:64)).foregroundStyle(paradiseAccent.opacity(0.8))}
                                    VStack {HStack {Text("FC 经典").font(.caption2.weight(.semibold)).padding(.horizontal,9).padding(.vertical,5).background(.black.opacity(0.8)).clipShape(Capsule());Spacer()};Spacer()}.padding(14)
                                }.frame(height:235)
                                VStack(alignment:.leading,spacing:12) {
                                    HStack {Text(game.title).font(.title2.bold());Spacer();Text(game.players ?? "FC 游戏").font(.caption).foregroundStyle(.secondary)}
                                    Text(game.subtitle).font(.subheadline).foregroundStyle(.secondary)
                                    Divider().opacity(0.5)
                                    HStack {Label("键盘操作",systemImage:"keyboard").font(.caption).foregroundStyle(.secondary);Spacer();Button {model.launch(game)} label:{Label("开始游戏",systemImage:"play.fill").font(.subheadline.bold()).padding(.horizontal,8).padding(.vertical,5)}.buttonStyle(.borderedProminent).tint(paradiseAccent).foregroundStyle(.black)}
                                }.padding(20)
                            }.background(Color.white.opacity(0.045)).clipShape(RoundedRectangle(cornerRadius:16)).overlay(RoundedRectangle(cornerRadius:16).stroke(Color.white.opacity(0.08)))
                        }
                    }
                    HStack(alignment:.top,spacing:10) {Image(systemName:"info.circle");Text("每款游戏保留原版菜单和规则。进入后可查看对应操作提示；双方按键都可以在设置中修改。").lineSpacing(5)}.font(.caption).foregroundStyle(.secondary).padding(16).frame(maxWidth:.infinity,alignment:.leading).background(Color.white.opacity(0.025)).clipShape(RoundedRectangle(cornerRadius:10))
                }.padding(32)
            }
        }
    }
}
