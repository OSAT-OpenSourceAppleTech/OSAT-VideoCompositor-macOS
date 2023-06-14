//
//  VideoEditor_SwiftUIApp.swift
//  VideoEditor-SwiftUI
//
//  Created by snbehar on 16/01/23.
//

import SwiftUI
import PhotosUI

@main

struct VideoEditor_SwiftUIApp: App {
    @StateObject var playerInstance = PlayerViewModel()
    
    var body: some Scene {
        WindowGroup("OSAT Video Editor", content: {
            ContentView()
                .environmentObject(playerInstance)
                .disabled(playerInstance.isProcessingVideo)
                .onDisappear(perform: {
                    NSApplication.shared.terminate(nil)
                })
            if playerInstance.openedPanel == .addWatermarkPanel {
                AddWatermarkView()
                    .environmentObject(playerInstance)
            }
            if playerInstance.openedPanel == .addImagePanel {
                AddImageView()
                    .environmentObject(playerInstance)
            }
            if playerInstance.openedPanel == .addTextPanel {
                AddTextView()
                    .environmentObject(playerInstance)
            }
            if playerInstance.openedPanel == .addGIFPanel {
                AddGIFView()
                    .environmentObject(playerInstance)
            }
            if playerInstance.openedPanel == .addTrimPanel {
                TrimViewController()
                    .environmentObject(playerInstance)
            }
        })
        .windowResizability(.contentMinSize)
    }
}
