import AppKit
let root=URL(fileURLWithPath:CommandLine.arguments[1])
let iconset=root.appendingPathComponent("artifacts/AppIcon.iconset")
try FileManager.default.createDirectory(at:iconset,withIntermediateDirectories:true)
for size in [16,32,128,256,512] {
    for retina in [false,true] {
        let pixels=size*(retina ? 2:1), s=CGFloat(pixels)
        let image=NSImage(size:NSSize(width:s,height:s))
        image.lockFocus()
        NSColor(calibratedRed:0.07,green:0.09,blue:0.10,alpha:1).setFill()
        NSBezierPath(roundedRect:NSRect(x:s*0.05,y:s*0.05,width:s*0.90,height:s*0.90),xRadius:s*0.20,yRadius:s*0.20).fill()
        NSColor(calibratedRed:0.78,green:0.94,blue:0.40,alpha:1).setFill()
        NSBezierPath(roundedRect:NSRect(x:s*0.18,y:s*0.25,width:s*0.64,height:s*0.50),xRadius:s*0.09,yRadius:s*0.09).fill()
        let text="乐" as NSString
        let attributes:[NSAttributedString.Key:Any]=[.font:NSFont.systemFont(ofSize:s*0.40,weight:.heavy),.foregroundColor:NSColor(calibratedRed:0.07,green:0.09,blue:0.10,alpha:1)]
        let textSize=text.size(withAttributes:attributes)
        text.draw(at:NSPoint(x:(s-textSize.width)/2,y:(s-textSize.height)/2),withAttributes:attributes)
        image.unlockFocus()
        let bitmap=NSBitmapImageRep(data:image.tiffRepresentation!)!
        let path=iconset.appendingPathComponent("icon_\(size)x\(size)\(retina ? "@2x":"").png")
        try bitmap.representation(using:.png,properties:[:])!.write(to:path)
    }
}
