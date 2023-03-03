//
//  AddWatermarkView.swift
//  VideoEditor-SwiftUI
//
//  Created by snbehar on 06/02/23.
//
import SwiftUI
import AVKit
import OSAT_VideoCompositor_macOS

struct AddWatermarkView: View {
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    @State private var watermarkText: String = ""
    @State private var watermarkFont: NSFont = .systemFont(ofSize: 12)
    @State private var watermarkTextColor: CGColor = .white
    @State private var watermarkTextFrame: NSRect = .zero
    @State private var watermarkImageFrame: NSRect = .zero
    @State private var watermarkImageFile: URL = URL(filePath: "")
    
    private var textLayer: CATextLayer {
        let layer = CATextLayer()
        layer.font = watermarkFont
        layer.fontSize = watermarkFont.pointSize
        layer.frame = watermarkTextFrame
        layer.foregroundColor = watermarkTextColor
        layer.string = watermarkText
        layer.name = "WatermarkTextLayer"
        return layer
    }
    
    private var imageLayer: CALayer {
        let layer = CALayer()
        layer.contents = NSImage(byReferencing: watermarkImageFile)
        layer.frame = watermarkImageFrame
        layer.name = "WatermarkImageLayer"
        return layer
    }

    var body: some View {
        VStack(alignment: .leading, content: {
            HStack(content: {
                Text("Text")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                TextField("Text", text: $watermarkText)
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                FontPicker("Font", selection: $watermarkFont)
                ColorPicker(selection: $watermarkTextColor, label: {
                    Text("Color")
                })
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Image Path")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 5))
                    .multilineTextAlignment(.leading)
                Text(watermarkImageFile.relativeString)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .frame(minWidth: 355, maxWidth: .infinity, alignment: .leading)
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.image, .rawImage]
                    if panel.runModal() == .OK {
                        watermarkImageFile = panel.url ?? URL(filePath: "")
                    }
                }, label: {
                    Image(systemName: "doc.fill.badge.plus")
                })
                .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Text Frame")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 17))
                    .fixedSize(horizontal: true, vertical: false)
                Text("x:")
                TextField("", value: $watermarkTextFrame.origin.x, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("y:")
                TextField("", value: $watermarkTextFrame.origin.y, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Height:")
                TextField("", value: $watermarkTextFrame.size.height, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Width:")
                TextField("", value: $watermarkTextFrame.size.width, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Image Frame")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 5))
                    .fixedSize(horizontal: true, vertical: false)
                Text("x:")
                TextField("", value: $watermarkImageFrame.origin.x, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("y:")
                TextField("", value: $watermarkImageFrame.origin.y, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Height:")
                TextField("", value: $watermarkImageFrame.size.height, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Width:")
                TextField("", value: $watermarkImageFrame.size.width, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Button("Submit", action: {
                    guard let playerItem = playerInstance.videoPlayer.playerView.player?.currentItem else { return }
                    let videoTimeRange = CMTimeRange(start: CMTime(value: 0, timescale: 1), duration: playerItem.duration)
                    
                    if (!watermarkText.isEmpty) {
                        playerInstance.createAddTextJob(text: watermarkText, frame: watermarkTextFrame, timeRange: videoTimeRange, textColor: NSColor(cgColor: watermarkTextColor) ?? .white, backgroundColor: .clear, font: watermarkFont)
                    }
                    
                    if (watermarkImageFile.absoluteString != URL(filePath: "").absoluteString) {
                        playerInstance.createAddImageJob(image: NSImage(byReferencing: watermarkImageFile), frame: watermarkImageFrame, timeRange: videoTimeRange)
                    }
                    
                    playerInstance.openedPanel = .noOpenPanel
                })
                
                Button("Preview Position", action: {
                    playerInstance.showPreview(layers: [textLayer, imageLayer])
                })
            })
            .frame(width: 500)
        })
        .frame(width: 500, height: 200)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct AddWatermarkView_Previews: PreviewProvider {
    @StateObject static var playerInstance = PlayerViewModel()
    static var previews: some View {
        AddWatermarkView()
            .environmentObject(playerInstance)
    }
}

class FontPickerDelegate {
    var parent: FontPicker

    init(_ parent: FontPicker) {
        self.parent = parent
    }
    
    @objc
    func changeFont(_ id: Any ){
        parent.fontSelected()
    }

}

public struct FontPicker: View {
    let labelString: String
    @Binding var font:NSFont
    
    @State var fontPickerDelegate:FontPickerDelegate? = nil
    
    public init(_ label: String, selection: Binding<NSFont>) {
        self.labelString = label
        self._font = selection
    }
    public var body: some View {
        HStack {
            Text(labelString)
            Button(action: {
                if NSFontPanel.shared.isVisible {
                    NSFontPanel.shared.orderOut(nil)
                    return
                }
                NSFontPanel.shared.toolbar?.isVisible = false
                NSFontPanel.shared.toolbarStyle = .unifiedCompact
                self.fontPickerDelegate = FontPickerDelegate(self)
                NSFontManager.shared.target = self.fontPickerDelegate
                NSFontPanel.shared.setPanelFont(self.font, isMultiple: false)
                NSFontPanel.shared.orderBack(nil)
            }, label: {
                Image(systemName: "textformat").resizable().scaledToFit()
            })
        }
    }
    
    func fontSelected() {
        self.font = NSFontPanel.shared.convert(self.font)
        //NSFontPanel.shared.orderOut(nil)
    }
}
