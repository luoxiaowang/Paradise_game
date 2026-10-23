import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window:NSWindow!
    private var model:AppModel!
    func applicationDidFinishLaunching(_ notification:Notification) {
        model=AppModel()
        window=NSWindow(contentRect:NSRect(x:0,y:0,width:1100,height:780),styleMask:[.titled,.closable,.miniaturizable,.resizable],backing:.buffered,defer:false)
        window.title="游戏乐园 · Paradise Game"
        window.minSize=NSSize(width:900,height:720)
        window.contentView=NSHostingView(rootView:RootView(model:model))
        window.backgroundColor=NSColor(calibratedRed:0.055,green:0.065,blue:0.08,alpha:1)
        window.delegate=self;window.center();window.setFrameAutosaveName("ParadiseMainWindow")
        window.collectionBehavior=[.fullScreenPrimary]
        let menu=NSMenu();let appItem=NSMenuItem();menu.addItem(appItem)
        let appMenu=NSMenu();appItem.submenu=appMenu
        appMenu.addItem(withTitle:"关于游戏乐园",action:#selector(about),keyEquivalent:"").target=self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle:"按键与声音…",action:#selector(settings),keyEquivalent:",").target=self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle:"隐藏游戏乐园",action:#selector(NSApplication.hide(_:)),keyEquivalent:"h")
        appMenu.addItem(withTitle:"退出游戏乐园",action:#selector(NSApplication.terminate(_:)),keyEquivalent:"q")
        let viewItem=NSMenuItem();viewItem.title="窗口";let viewMenu=NSMenu(title:"窗口");viewItem.submenu=viewMenu
        viewMenu.addItem(withTitle:"最小化",action:#selector(NSWindow.performMiniaturize(_:)),keyEquivalent:"m")
        let full=viewMenu.addItem(withTitle:"切换全屏",action:#selector(NSWindow.toggleFullScreen(_:)),keyEquivalent:"f");full.keyEquivalentModifierMask=[.control,.command]
        menu.addItem(viewItem);NSApp.mainMenu=menu
        window.makeKeyAndOrderFront(nil);NSApp.activate(ignoringOtherApps:true)
    }
    @objc private func settings(){model.showSettings()}
    @objc private func about(){NSApp.orderFrontStandardAboutPanel(options:[.applicationName:"游戏乐园",.applicationVersion:"1.1.0",.credits:NSAttributedString(string:"收录游戏：坦克大战、超级玛丽\n模拟核心：Nestopia（GPL-2.0）\n原游戏版权归原权利人所有。")])}
    func applicationShouldTerminateAfterLastWindowClosed(_ sender:NSApplication)->Bool {true}
    func applicationWillTerminate(_ notification:Notification){model?.stop()}
}
let app=NSApplication.shared
let delegate=AppDelegate()
app.setActivationPolicy(.regular)
app.delegate=delegate
app.run()
