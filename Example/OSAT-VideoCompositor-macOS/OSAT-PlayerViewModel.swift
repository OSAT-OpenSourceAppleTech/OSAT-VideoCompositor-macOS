//
//  OSAT-PlayerViewUtils.swift
//  OSAT-VideoCompositor-macOS_Example
//
//  Created by snbehar on 09/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import OSAT_VideoCompositor_macOS
import SwiftUI
import AVKit

enum openPanel: Int {
    case noOpenPanel = 0
    case addWatermarkPanel = 1
    case addImagePanel = 2
    case addTextPanel = 3
    case addGIFPanel = 4
}

class PlayerViewModel: ObservableObject {
    @Published var inputVideoURL: URL = URL(filePath: "")
    @Published var seekBarValue: Float = 0.0
    @Published var volumeLevel: Float = 1.0
    @Published var loopButtonState: Bool = false
    @Published var isPlaying: Bool = false
    @Published var timeElapsed: String = "--:--/--:--"
    @Published var readyToPlay: Bool = false
    @Published var isProcessingVideo: Bool = false
    
    @Published var openedPanel: openPanel = .noOpenPanel
    
    var jobsList: [OSATAnnotationProtocol] = []
    
    let videoPlayer = AVPlayerViewWrapper(playerView: AVPlayerView())
    let videoEditor = OSATVideoComposition()
    
    func initialiseVideoPlayer(with url: URL) {
        videoPlayer.playerView.player = AVPlayer(url: url)
        videoPlayer.playerView.player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: .main, using: { time in
            self.updateElapsedTime()
            self.updateSeekPosition()
        });
        inputVideoURL = url
        resetUI()
        readyToPlay = true
    }
    
    func createAddImageJob(image: NSImage, frame: NSRect, timeRange: CMTimeRange?) {
        let job = OSATImageAnnotation(image: image, frame: frame, timeRange: timeRange)
        jobsList.append(job)
    }
    
    func createAddTextJob(text: String, frame: NSRect, timeRange: CMTimeRange, textColor: NSColor, backgroundColor: NSColor, font: NSFont) {
        let job = OSATTextAnnotation(text: text, frame: frame, timeRange: timeRange, attributedText: nil, textColor: textColor, backgroundColor: backgroundColor, font: font)
        jobsList.append(job)
    }
    
    func exportVideo() {
        isProcessingVideo = true
        videoPlayer.playerView.player?.pause()
        videoEditor.createVideoComposition(sourceVideoURL: inputVideoURL, exportURL: inputVideoURL.deletingLastPathComponent(), annotations: jobsList, completionHandler: { exportURL in
            let savePanel = NSSavePanel()
            savePanel.title = "Save"
            savePanel.nameFieldLabel = "Save field"
            savePanel.nameFieldStringValue = "testFile.mov"
            savePanel.showsTagField = false
            savePanel.canCreateDirectories = true
            savePanel.level = .modalPanel + 2  //If there is a target=_blank pop-up, we need to open it in-front.
                        
            let response = savePanel.runModal()
            if response == .OK  {
            guard let destination = savePanel.url else { return }
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: exportURL, to: destination)
                } catch {
                    print("Error while saving file! Aborting save file!")
                }
            }
            self.isProcessingVideo = false
            self.initialiseVideoPlayer(with: savePanel.url ?? URL(fileURLWithPath: ""))
            self.jobsList = []
        }, errorHandler: { _ in
            
        })
    }

    func updateElapsedTime() {
        var seconds = NSString(format: "%02f", videoPlayer.playerView.player?.currentTime().seconds ?? 0)
        let minutes = NSString(format: "%02d", seconds.intValue / 60);
        seconds = NSString(format: "%02d", seconds.intValue % 60)
        
        var totalSeconds = NSString(format: "%02f", videoPlayer.playerView.player?.currentItem?.duration.seconds ?? 0)
        let totalMinutes = NSString(format: "%02d", totalSeconds.intValue / 60);
        totalSeconds = NSString(format: "%02d", totalSeconds.intValue % 60)
        
        var timeElapsedString : String = minutes.appending(":")
        timeElapsedString.append(seconds as String)
        timeElapsedString.append("/")
        timeElapsedString.append(totalMinutes as String)
        timeElapsedString.append(":")
        if (totalSeconds.length == 1) {
            timeElapsedString.append("0")
        }
        timeElapsedString.append(totalSeconds as String)
        
        timeElapsed = timeElapsedString
    }

    func updateSeekPosition() {
        let elapsedSeconds = videoPlayer.playerView.player?.currentTime().seconds ?? 0
        let totalSeconds = videoPlayer.playerView.player?.currentItem?.duration.seconds ?? 0
        seekBarValue = Float(elapsedSeconds / totalSeconds);
        if (seekBarValue == 1 && isPlaying) {
            videoPlayer.playerView.player?.seek(to: kCMTimeZero)
            if (loopButtonState) {
                videoPlayer.playerView.player?.play()
            } else {
                isPlaying = false
            }
        }
    }
    
    func showPreview(layers: [CALayer]) {
        videoPlayer.playerView.layer?.sublayers?.forEach({
            if $0.name != "AVDesktopPlayerViewContentView" {
                $0.removeFromSuperlayer()
            }
        })
        
        let goldenWidthRatio = videoPlayer.playerView.videoBounds.width / (videoPlayer.playerView.player?.currentItem?.presentationSize.width ?? 1)
        let goldenHeightRatio = videoPlayer.playerView.videoBounds.height / (videoPlayer.playerView.player?.currentItem?.presentationSize.height ?? 1)
        
        layers.forEach({
            let adjustedFrame = NSRect(x: (videoPlayer.playerView.videoBounds.minX) + ($0.frame.minX * goldenWidthRatio), y: (videoPlayer.playerView.videoBounds.minY) + ($0.frame.minY * goldenHeightRatio), width: $0.frame.width * (goldenWidthRatio), height: $0.frame.height * (goldenHeightRatio))
            $0.frame = adjustedFrame
            videoPlayer.playerView.layer?.addSublayer($0)
        })
    }
    
    func resetUI() {
        seekBarValue = 0.0
        volumeLevel = 1.0
        loopButtonState = false
        isPlaying = false
        timeElapsed = "--:--/--:--"
        readyToPlay = false
        isProcessingVideo = false
    }
}

struct AVPlayerViewWrapper: NSViewRepresentable {
    let playerView: AVPlayerView
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    func makeNSView(context: Context) -> some NSView {
        playerView.controlsStyle = .none
        return playerView
    }
}
