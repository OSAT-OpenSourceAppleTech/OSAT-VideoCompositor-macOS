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
    case addTrimPanel = 5
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
    
    private(set) var videoItems = [OSATVideoSource]()
    
    var jobsList: [OSATAnnotationProtocol] = []
    
    let videoPlayer = AVPlayerViewWrapper(playerView: AVPlayerView())
    let videoEditor = OSATVideoComposition()
    private var mainComposition: (mixComposition: AVMutableComposition, videoComposition: AVVideoComposition)?
    
    func addVideo(with url: URL, startTime: Double = .nan, duration: Double = .nan) {
        let newItem = OSATVideoSource(videoURL: url, startTime: startTime, duration: duration)
        videoItems.append(newItem)
    }
    
    private func initVideoPlayer() {
        guard let mainComposition = self.mainComposition else { return }
        
        let playerItem = AVPlayerItem.init(asset: mainComposition.mixComposition)
        playerItem.videoComposition = mainComposition.videoComposition
        if videoPlayer.playerView.player == nil {
            videoPlayer.playerView.player = AVPlayer.init(playerItem: playerItem)
            videoPlayer.playerView.player?.addPeriodicTimeObserver(
                forInterval: CMTime(seconds: 0.01, preferredTimescale: mainComposition.mixComposition.duration.timescale),
                queue: nil,
                using: { (currentTime) in
                    self.updateElapsedTime()
                    self.updateSeekPosition()
                })
            guard let player = videoPlayer.playerView.player else { return }
            player.seek(to: kCMTimeZero)
            resetUI()
            readyToPlay = true
            
        }
        else {
            guard let player = videoPlayer.playerView.player else { return }
            player.replaceCurrentItem(with: playerItem)
            resetUI()
            readyToPlay = true
        }
    }
    
    func createAddImageJob(image: NSImage, frame: NSRect, timeRange: CMTimeRange?) {
        let job = OSATImageAnnotation(image: image, frame: frame, timeRange: timeRange)
        jobsList.append(job)
    }
    
    func createAddTextJob(text: String, frame: NSRect, timeRange: CMTimeRange, textColor: NSColor, backgroundColor: NSColor, font: NSFont) {
        let job = OSATTextAnnotation(text: text, frame: frame, timeRange: timeRange, attributedText: nil, textColor: textColor, backgroundColor: backgroundColor, font: font)
        jobsList.append(job)
    }
    
    func trimVideo(index: Int, startTime: Double, duration: Double) {
        guard !videoItems.isEmpty else { return }
        guard index < videoItems.count else { return }
        let sourceItem = OSATVideoSource(videoURL: videoItems[index].videoURL, startTime: startTime, duration: duration)
        self.mainComposition = videoEditor.trimVideo(sourceItem: sourceItem)
        initVideoPlayer()
    }
    
    func mergeVideos() {
        guard !videoItems.isEmpty else { return }
        self.mainComposition = videoEditor.mergeVideo(from: videoItems)
        initVideoPlayer()
    }
    
    func exportVideo() {
        isProcessingVideo = true
        videoPlayer.playerView.player?.pause()
        videoEditor.addAnnotations(sourceItem: self.videoItems[0], exportURL: inputVideoURL.deletingLastPathComponent(), annotations: jobsList, completionHandler: { exporter in
            let savePanel = NSSavePanel()
            savePanel.title = "Save"
            savePanel.nameFieldLabel = "Save field"
            savePanel.nameFieldStringValue = "testFile.mov"
            savePanel.showsTagField = false
            savePanel.canCreateDirectories = true
            savePanel.level = .modalPanel + 2  //If there is a target=_blank pop-up, we need to open it in-front.
                        
            let response = savePanel.runModal()
            if response == .OK  {
                guard let destination = savePanel.url, let outUrl = exporter.outputURL else { return }
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.moveItem(at: outUrl, to: destination)
                    self.videoItems.removeAll()
                    self.addVideo(with: destination)
                    self.mergeVideos()
                } catch {
                    print("Error while saving file! Aborting save file!")
                }
            }
            self.isProcessingVideo = false
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
