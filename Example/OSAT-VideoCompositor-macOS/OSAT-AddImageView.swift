//
//  OSAT-AddImageView.swift
//  OSAT-VideoCompositor-macOS_Example
//
//  Created by snbehar on 13/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import AVKit

struct AddImageView: View {
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    @State private var timeRange: CMTimeRange = CMTimeRange()
    @State private var imageFrame: NSRect = .zero
    @State private var imageFile: URL = URL(filePath: "")
    
    private var imageLayer: CALayer {
        let layer = CALayer()
        layer.contents = NSImage(byReferencing: imageFile)
        layer.frame = imageFrame
        layer.name = "ImageLayer"
        return layer
    }

    var body: some View {
        VStack(alignment: .leading, content: {
            HStack(content: {
                Text("Image Path")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 5))
                    .multilineTextAlignment(.leading)
                Text(imageFile.relativeString)
                    .padding(EdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5))
                    .frame(minWidth: 355, maxWidth: .infinity, alignment: .leading)
                Button(action: {
                    let panel = NSOpenPanel()
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.image, .rawImage]
                    if panel.runModal() == .OK {
                        imageFile = panel.url ?? URL(filePath: "")
                    }
                }, label: {
                    Image(systemName: "doc.fill.badge.plus")
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
                Text("Image Frame")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 5))
                    .fixedSize(horizontal: true, vertical: false)
                Text("x:")
                TextField("", value: $imageFrame.origin.x, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("y:")
                TextField("", value: $imageFrame.origin.y, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Height:")
                TextField("", value: $imageFrame.size.height, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Width:")
                TextField("", value: $imageFrame.size.width, formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Button("Submit", action: {
                    playerInstance.createAddImageJob(image: NSImage(byReferencing: imageFile), frame: imageFrame, timeRange: timeRange)
                    playerInstance.openedPanel = .noOpenPanel
                })
                
                Button("Preview Position", action: {
                    playerInstance.showPreview(layers: [imageLayer])
                })
            })
            .frame(width: 500)
        })
        .frame(width: 500, height: 200)
        .fixedSize(horizontal: true, vertical: true)
    }
}

struct AddImageView_Previews: PreviewProvider {
    static var previews: some View {
        AddImageView()
    }
}
