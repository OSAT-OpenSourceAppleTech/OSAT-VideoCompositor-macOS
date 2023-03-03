//
//  OSAT-AddTextView.swift
//  OSAT-VideoCompositor-macOS_Example
//
//  Created by snbehar on 13/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import AVKit

struct AddTextView: View {
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    @State private var text: String = ""
    @State private var font: NSFont = .systemFont(ofSize: 12)
    @State private var textColor: CGColor = .black
    @State private var textFrame: NSRect = .zero
    @State private var timeRange: CMTimeRange = CMTimeRange()
    
    private var textLayer: CATextLayer {
        let layer = CATextLayer()
        layer.frame = textFrame
        layer.font = font
        layer.fontSize = font.pointSize
        layer.isWrapped = true
        layer.foregroundColor = textColor
        layer.string = text
        layer.name = "TextLayer"
        return layer
    }
    
    var body: some View {
        VStack(content: {
            HStack(content: {
                Text("Text")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                TextField("Text", text: $text)
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                FontPicker("Font", selection: $font)
                ColorPicker(selection: $textColor, label: {
                    Text("Color")
                })
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Time Range")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 17))
                    .fixedSize(horizontal: true, vertical: false)
                Text("From (s):")
                TextField("0", value: Binding(get: { return timeRange.start.seconds}, set: { newValue in
                    if newValue.isFinite {
                        timeRange.start = CMTime(value: Int64(newValue), timescale: 1)
                    } else {
                        timeRange.start = CMTime(value: 0, timescale: 1)
                    }
                }), formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("To (s):")
                TextField("0", value: Binding(get: { return timeRange.end.seconds }, set: { newValue in
                    if newValue.isFinite {
                        timeRange.duration = CMTime(seconds: (newValue - timeRange.start.seconds), preferredTimescale: 1)
                    } else {
                        timeRange.duration = CMTime(seconds: 0, preferredTimescale: 1)
                    }
                }), formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Text Frame")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 17))
                    .fixedSize(horizontal: true, vertical: false)
                Text("x:")
                TextField("", value: $textFrame.origin.x, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("y:")
                TextField("", value: $textFrame.origin.y, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Height:")
                TextField("", value: $textFrame.size.height, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Width:")
                TextField("", value: $textFrame.size.width, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Button("Submit", action: {
                    if (!text.isEmpty) {
                        playerInstance.createAddTextJob(text: text, frame: textFrame, timeRange: timeRange, textColor: NSColor(cgColor: textColor) ?? .white, backgroundColor: .clear, font: font)
                    }
                    playerInstance.openedPanel = .noOpenPanel
                })
                
                Button("Preview Position", action: {
                    playerInstance.showPreview(layers: [textLayer])
                })
            })
            .frame(width: 500)
        })
        .frame(width: 500, height: 200)
    }
}

struct OSAT_AddTextView_Previews: PreviewProvider {
    static var previews: some View {
        AddTextView()
    }
}
