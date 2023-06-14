//
//  OSAT-TrimViewController.swift
//  OSAT-VideoCompositor-macOS_Example
//
//  Created by uchauhan on 09/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI
import AVFoundation

struct TrimViewController: View {
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    @State private var videoIndex: Int = 0
    @State private var timeRange: CMTimeRange = CMTimeRange()
    
    var body: some View {
        VStack(content: {
            HStack(content: {
                Text("Video Index")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 17))
                    .fixedSize(horizontal: true, vertical: false)
                TextField("",
                          value: Binding( get: { return videoIndex },
                                          set: { newValue in
                    if newValue < playerInstance.videoItems.count {
                        self.videoIndex = newValue
                    }
                }), formatter: NumberFormatter())
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Text("Time Range")
                    .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 17))
                    .fixedSize(horizontal: true, vertical: false)
                Text("Start Time(s):")
                TextField("0", value: Binding(get: { return timeRange.start.seconds}, set: { newValue in
                    if newValue <= playerInstance.videoItems[videoIndex].duration && newValue >= 0 {
                        timeRange.start = CMTime(seconds: newValue, preferredTimescale: 1)
                    }
                }), formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 5))
                Text("Duration (s):")
                TextField("0", value: Binding(get: { return timeRange.end.seconds }, set: { newValue in
                    if newValue <= playerInstance.videoItems[videoIndex].duration && newValue >= 0 && (newValue - timeRange.start.seconds) > 5 {
                        timeRange.duration = CMTime(seconds: (newValue - timeRange.start.seconds), preferredTimescale: 1)
                    }
                }), formatter: NumberFormatter())
                    .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            
            HStack(content: {
                Button("Done", action: {
                    playerInstance.trimVideo(index: videoIndex, startTime: timeRange.start.seconds, duration: timeRange.duration.seconds)
                    playerInstance.openedPanel = .noOpenPanel
                })
            })
        })
        .frame(width: 500, height: 200)
    }
}

struct OSAT_TrimViewController_Previews: PreviewProvider {
    static var previews: some View {
        TrimViewController()
    }
}
