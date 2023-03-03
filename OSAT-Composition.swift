//
//  OSAT-Composition.swift
//  OSAT-VideoCompositor-macOS
//
//  Created by snbehar on 10/02/23.
//

import AVFoundation
import AppKit

public struct OSATVideoComposition {
    
    public init() {}
    /// Creates a video composition for a source video with annotations
    /// - Parameters:
    ///   - sourceVideoURL: URL for the source video
    ///   - exportURL: URL for saving the exported video
    ///   - annotations: list of annotations confroming to OSATAnnotationProtocol
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    public func createVideoComposition(sourceVideoURL: URL, exportURL: URL, annotations: [OSATAnnotationProtocol], completionHandler: @escaping(_ exportedFileURL: URL) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        
        let composition = AVMutableComposition()
        let asset = AVAsset(url: sourceVideoURL)
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            NSLog("Video asset is corrupt.", "")
            errorHandler(.videoAssetCorrupt)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            NSLog("Failed to insert audio track", "")
            errorHandler(.videoAssetCorrupt)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        
        let videoSize: CGSize = assetTrack.naturalSize
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        videoLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: videoSize.width,
            height: videoSize.height)
        
        let outputLayer = CALayer()
        outputLayer.addSublayer(videoLayer)
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        
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
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
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
            
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
            
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch (export.status) {
                case .cancelled:
                    print("Exporting cancelled");
                case .completed:
                    print("Exporting completed");
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
        completionHandler(exportURL)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
}
