//
//  OSAT-Composition.swift
//  OSAT-VideoCompositor-macOS
//
//  Created by snbehar on 10/02/23.
//

import AVFoundation
import AppKit
public struct OSATVideoSource {
    public let videoURL: URL
    public let startTime: Double
    public let duration: Double
    public init(videoURL: URL, startTime: Double, duration: Double) {
        self.videoURL = videoURL
        let asset = AVAsset(url: videoURL)
        if startTime.isNaN {
            self.startTime = .zero
        } else {
            self.startTime = startTime
        }
        if duration.isNaN {
            self.duration = asset.duration.seconds
        } else {
            self.duration = duration
        }
    }
}
public struct OSATVideoComposition {
    
    public init() {}
    /// Creates a video composition for a source video with annotations
    /// - Parameters:
    ///   - sourceVideoURL: URL for the source video
    ///   - exportURL: URL for saving the exported video
    ///   - annotations: list of annotations confroming to OSATAnnotationProtocol
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    public func createVideoComposition(sourceItems:[OSATVideoSource], animation:Bool = true, exportURL: URL, annotations: [OSATAnnotationProtocol], completionHandler: @escaping(_ exportedFileURL: URL) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        var insertTime = CMTime.zero
        // currently it's support only single canvas size
        let defaultSize = CGSize(width: 1280, height: 1280) // Default video size
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []

        // Init composition
        let mixComposition = AVMutableComposition()
        
        for videoSource in sourceItems {
            let videoAsset = AVAsset(url: videoSource.videoURL)
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            // Get audio track
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = videoSource.startTime.toCMTime() // CMTime.zero
                let duration = videoSource.duration.toCMTime() // videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                // Add layer instruction for video track
                if let videoCompositionTrack = videoCompositionTrack {
                    let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack, asset: videoAsset, targetSize: defaultSize)
                    
                    // Hide video track before changing to new track
                    let endTime = CMTimeAdd(insertTime, duration)
                    
                    if animation {
                        let durationAnimation = 1.0.toCMTime()
                        
                        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: endTime, duration: durationAnimation))
                    }
                    else {
                        layerInstruction.setOpacity(0, at: endTime)
                    }
                    
                    arrayLayerInstructions.append(layerInstruction)
                }
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }
        
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: defaultSize)
        
        videoLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: defaultSize.width,
            height: defaultSize.height)
        
        let outputLayer = CALayer()
        outputLayer.addSublayer(videoLayer)
        outputLayer.frame = CGRect(origin: .zero, size: defaultSize)
        
        annotations.forEach {
            let annotationLayer = $0.getAnnotationLayer()
            annotationLayer.frame = $0.frame
            annotationLayer.opacity = 0
            
            let scaleAnimation = CABasicAnimation(keyPath: "opacity")
            scaleAnimation.fromValue = 1
            scaleAnimation.toValue = 1
            scaleAnimation.beginTime = $0.timeRange?.start.seconds ?? 0
            scaleAnimation.duration = ($0.timeRange?.duration.seconds ?? 0) / 2
            scaleAnimation.repeatCount = 1
            scaleAnimation.autoreverses = true
            scaleAnimation.timingFunction = CAMediaTimingFunction(name: .default)
            scaleAnimation.isRemovedOnCompletion = false
            if scaleAnimation.beginTime == 0 {
                scaleAnimation.beginTime = .leastNonzeroMagnitude
            }
            
            annotationLayer.add(scaleAnimation, forKey: "opacity")
            outputLayer.addSublayer(annotationLayer)
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainVideoComposition = AVMutableVideoComposition()
        mainVideoComposition.instructions = [mainInstruction]
        mainVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        mainVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainVideoComposition.renderSize = defaultSize
        
        
        guard let export = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
            
        let videoName = UUID().uuidString
        let exportURL = URL(filePath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
            
        export.videoComposition = mainVideoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        DispatchQueue.global(qos: .utility).async {
            export.exportAsynchronously {
                DispatchQueue.main.async {
                    switch (export.status) {
                    case .cancelled:
                        print("Exporting cancelled");
                    case .completed:
                        print("Exporting completed");
                        completionHandler(exportURL)
                    case .exporting:
                        print("Exporting ...");
                    case .failed:
                        print("Exporting failed");
                    default:
                        print("Exporting with other result");
                    }
                    if let error = export.error
                    {
                        print("Error:\n\(error)");
                    }
                }
            }
        }
    }
    
    /// Make a video from multiple videos. The user is able to merge and trim videos.
    /// - Parameters:
    ///   - sourceItems: add source videos
    ///   - animation: set `true` for video end animation otherwise false
    ///   - exportURL: URL for saving the exported video
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    public func makeMultiVideoComposition(from sourceItems:[OSATVideoSource], animation:Bool = true) -> (AVMutableComposition, AVMutableVideoComposition) {
        var insertTime = CMTime.zero
        // currently it's support only single canvas size
        let defaultSize = CGSize(width: 1280, height: 1280) // Default video size
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []

        // Init composition
        let mixComposition = AVMutableComposition()
        
        for videoSource in sourceItems {
            let videoAsset = AVAsset(url: videoSource.videoURL)
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            // Get audio track
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = videoSource.startTime.toCMTime() // CMTime.zero
                let duration = videoSource.duration.toCMTime() // videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                // Add layer instruction for video track
                if let videoCompositionTrack = videoCompositionTrack {
                    let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack, asset: videoAsset, targetSize: defaultSize)
                    
                    // Hide video track before changing to new track
                    let endTime = CMTimeAdd(insertTime, duration)
                    
                    if animation {
                        let durationAnimation = 1.0.toCMTime()
                        
                        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: endTime, duration: durationAnimation))
                    }
                    else {
                        layerInstruction.setOpacity(0, at: endTime)
                    }
                    
                    arrayLayerInstructions.append(layerInstruction)
                }
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainVideoComposition = AVMutableVideoComposition()
        mainVideoComposition.instructions = [mainInstruction]
        mainVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainVideoComposition.renderSize = defaultSize
        
        return (mixComposition, mainVideoComposition)
        // do export
        // export(composition: mixComposition, videoComposition: mainVideoComposition, exportURL: exportURL, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    private func export(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, exportURL: URL, completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError)->Void) {
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = exportURL.appendingPathComponent(videoName).appendingPathExtension("mp4")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completionHandler(export)
                default:
                    print(export.error ?? "")
                    errorHandler(.assetExportSessionFailed)
                    break
                }
            }
        })
    }
    
    private func videoCompositionInstructionForTrack(track: AVCompositionTrack?, asset: AVAsset, targetSize: CGSize) -> AVMutableVideoCompositionLayerInstruction {
        guard let track = track else {
            return AVMutableVideoCompositionLayerInstruction()
        }
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transform = assetTrack.fixedPreferredTransform
        let assetOrientation = transform.orientation
        
        let scaleToFitRatio = min(targetSize.width / assetTrack.naturalSize.width, targetSize.width / assetTrack.naturalSize.height)
        if assetOrientation.isPortrait {
            // Scale to fit target size
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            
            // Align center Y
            let newX = targetSize.width/2 - ((assetTrack.naturalSize.height / 2) * scaleToFitRatio)
            let newY = targetSize.height/2 - ((assetTrack.naturalSize.width / 2) * scaleToFitRatio)
            let moveCenterFactor = CGAffineTransform(translationX: newX, y: newY)
            
            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)

            instruction.setTransform(finalTransform, at: .zero)
        } else {
            // Scale to fit target size
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            
            // Align center Y
            let newY = targetSize.height/2 - (assetTrack.naturalSize.height * scaleToFitRatio)/2
            let moveCenterFactor = CGAffineTransform(translationX: 0, y: newY)
            
            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)
            
            instruction.setTransform(finalTransform, at: .zero)
        }

        return instruction
    }
    
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        instruction.setTransform(transform, at: .zero)
        return instruction
    }
}
