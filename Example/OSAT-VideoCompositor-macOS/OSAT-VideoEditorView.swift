//
//  ContentView.swift
//  VideoEditor-SwiftUI
//
//  Created by snbehar on 20/01/23.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    var body: some View {
        VStack(alignment: .leading, content: {
            ZStack(alignment: .center, content: {
                playerInstance.videoPlayer
                if (playerInstance.isProcessingVideo) {
                    ProgressView()
                }
            })
            HStack(alignment: .top, content: {
                Button(playerInstance.isPlaying ? "Pause" : "Play", action: {
                    if (playerInstance.isPlaying) {
                        playerInstance.videoPlayer.playerView.player?.pause()
                    } else {
                        playerInstance.videoPlayer.playerView.player?.play()
                    }
                    playerInstance.isPlaying.toggle()
                })
                .disabled(!playerInstance.readyToPlay)
                .disabled(!(playerInstance.openedPanel == .noOpenPanel))
                .padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 0))
                
                Button("Stop", action: {
                    playerInstance.videoPlayer.playerView.player?.pause()
                    playerInstance.videoPlayer.playerView.player?.seek(to: kCMTimeZero)
                    playerInstance.isPlaying = false
                })
                .disabled(!playerInstance.readyToPlay)
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                
                Slider(value: Binding(get: { return playerInstance.seekBarValue }, set: { newValue in
                    playerInstance.seekBarValue = newValue
                    let seekTime =  CMTimeMultiplyByFloat64(playerInstance.videoPlayer.playerView.player?.currentItem?.duration ?? CMTime(value: 0, timescale: 1), Float64(playerInstance.seekBarValue))
                    playerInstance.videoPlayer.playerView.player?.seek(to: seekTime, toleranceBefore: CMTime(value: 1, timescale: 1), toleranceAfter: CMTime(value: 1, timescale: 1))
                }))
                .disabled(!playerInstance.readyToPlay)
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                
                Text(playerInstance.timeElapsed)
                    .disabled(!playerInstance.readyToPlay)
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                
                Slider(value: Binding(get: { return playerInstance.volumeLevel }, set: { newValue in
                    playerInstance.volumeLevel = newValue
                    playerInstance.videoPlayer.playerView.player?.volume = newValue
                }), label: {
                    Text("Vol")
                })
                .disabled(!playerInstance.readyToPlay)
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                .frame(width: 130)
                
                Toggle(isOn: $playerInstance.loopButtonState, label: {
                    Text("Loop")
                })
                .disabled(!playerInstance.readyToPlay)
                .onChange(of: playerInstance.loopButtonState, perform: { value in
                    playerInstance.loopButtonState = value
                })
                .padding(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 10))
            })
            HStack(content: {
                Button("Add Video", action: {
                    DispatchQueue.main.async {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        panel.allowedContentTypes = [.video, .mpeg2Video, .appleProtectedMPEG4Video, .mpeg4Movie, .movie, .quickTimeMovie]
                        if panel.runModal() == .OK, let itemUrl = panel.url {
                            playerInstance.addVideo(with: itemUrl)
                        }
                        playerInstance.jobsList = []
                        playerInstance.mergeVideos()
                    }
                })
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 5, trailing: 0))
                
                Toggle(isOn: Binding(get: { return playerInstance.openedPanel == .addTrimPanel }, set: { newValue in
                    playerInstance.openedPanel = newValue ? .addTrimPanel : .noOpenPanel
                }), label: {
                    Text("Trim Video")
                })
                .toggleStyle(.button)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
                
                Toggle(isOn: Binding(get: { return playerInstance.openedPanel == .addWatermarkPanel }, set: { newValue in
                    playerInstance.openedPanel = newValue ? .addWatermarkPanel : .noOpenPanel
                }), label: {
                    Text("Add Watermark")
                })
                .toggleStyle(.button)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
                
                Toggle(isOn: Binding(get: { return playerInstance.openedPanel == .addImagePanel }, set: { newValue in
                    playerInstance.openedPanel = newValue ? .addImagePanel : .noOpenPanel
                }), label: {
                    Text("Add Image")
                })
                .toggleStyle(.button)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
                
                Toggle(isOn: Binding(get: { return playerInstance.openedPanel == .addTextPanel }, set: { newValue in
                    playerInstance.openedPanel = newValue ? .addTextPanel : .noOpenPanel
                }), label: {
                    Text("Add Text")
                })
                .toggleStyle(.button)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
                
                Toggle(isOn: Binding(get: { return playerInstance.openedPanel == .addGIFPanel }, set: { newValue in
                    playerInstance.openedPanel = newValue ? .addGIFPanel : .noOpenPanel
                }), label: {
                    Text("Add GIF")
                })
                .toggleStyle(.button)
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
                
                Button("Export Video", action: {
                    playerInstance.exportVideo()
                })
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 5, trailing: 0))
                .disabled(!playerInstance.readyToPlay)
            })
        })
        .frame(minWidth: 510, minHeight: 510)
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static var playerInstance = PlayerViewModel()
    static var previews: some View {
        ContentView()
            .environmentObject(playerInstance)
    }
}
