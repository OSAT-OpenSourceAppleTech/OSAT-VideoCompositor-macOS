import Cocoa
import AVFoundation

public class VideoEditor {
    public init() {
    }
    
    public func addWatermark(fromVideoAt videoURL: URL, image: NSImage? = nil, watermarkString: String?, watermarkPosition: Int, color: NSColor, onComplete: @escaping (URL?) -> Void) {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()
        
        guard
            let compositionTrack = composition.addMutableTrack(
                withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
            let assetTrack = asset.tracks(withMediaType: .video).first
        else {
            print("Something is wrong with the asset.")
            onComplete(nil)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioAssetTrack,
                    at: .zero)
            }
        } catch {
            print(error)
            onComplete(nil)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        
        let videoSize: CGSize = assetTrack.naturalSize
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        videoLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: videoSize.width,
            height: videoSize.height)
        
        let imageFrame = addImage(image, to: overlayLayer, videoSize: videoSize, requiredSize: CGSize(width: 40, height: 40), requiredPosition: watermarkPosition)
        
        addText(watermarkString, to: overlayLayer, videoSize: videoSize, watermarkPosition: watermarkPosition, imageFrame: imageFrame, color: color)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(
            for: compositionTrack,
            assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            print("Cannot create export session.")
            onComplete(nil)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    onComplete(exportURL)
                default:
                    print("Something went wrong during export.")
                    print(export.error ?? "unknown error")
                    onComplete(nil)
                    break
                }
            }
        }
    }
    
    private func addImage(_ image: NSImage?, to layer: CALayer, videoSize: CGSize, requiredSize: CGSize, requiredPosition: Int) -> CGRect{
        guard let cgImage = image?.cgImage, let image = image else { return .zero }
        let imageLayer = CALayer()
        
        let aspect: CGFloat = image.size.width/image.size.height
        let width = CGFloat(Int(videoSize.width / 6))
        let height = width / aspect
        imageLayer.frame = getWaterMarkFrame(videoSize: videoSize, currentElementFrame: CGSize(width: width, height: height), requiredPosition: requiredPosition, previousElemetPosition: .zero)
        
        imageLayer.contents = cgImage
        layer.addSublayer(imageLayer)
        return imageLayer.frame
    }
    
    private func addText(_ text: String?, to layer: CALayer, videoSize: CGSize, watermarkPosition: Int, imageFrame: CGRect, color: NSColor) {
        guard let text  = text else { return }
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttributes([.font: NSFont.systemFont(ofSize: 25), .foregroundColor: color], range: NSRange(location: 0, length: attributedText.length))
        
        let textLayer = CATextLayer()
        textLayer.string = attributedText
        textLayer.shouldRasterize = true
        textLayer.backgroundColor = NSColor.clear.cgColor
        textLayer.alignmentMode = .center
        textLayer.frame = getWaterMarkFrame(videoSize: videoSize, currentElementFrame: textLayer.preferredFrameSize(), requiredPosition: watermarkPosition, previousElemetPosition: imageFrame)
        textLayer.displayIfNeeded()
        
        layer.addSublayer(textLayer)
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
    private func getWaterMarkFrame(videoSize: CGSize, currentElementFrame: CGSize, requiredPosition: Int, previousElemetPosition: CGRect) -> CGRect {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let padding:CGFloat = 15
        let prevElementAvailable = previousElemetPosition.width != .zero
        switch requiredPosition {
        case 0:
            x += padding
            y += videoSize.height - currentElementFrame.height - padding - (previousElemetPosition.height == 0 ? 0 : (previousElemetPosition.height + 7))
        case 1:
            y += videoSize.height - currentElementFrame.height - padding - (previousElemetPosition.height == 0 ? 0 : (previousElemetPosition.height + 7))
            x += videoSize.width - currentElementFrame.width - padding
        case 3:
            x += videoSize.width - currentElementFrame.width - padding
            y += padding + (previousElemetPosition.height == 0 ? 0 : (previousElemetPosition.height + 7))
        default:
            x += padding
            y += padding + (previousElemetPosition.height == 0 ? 0 : (previousElemetPosition.height + 7))
        }
        if prevElementAvailable {
            switch requiredPosition {
            case 0:
                x += (previousElemetPosition.width - currentElementFrame.width)/2
            case 1:
                x += -(previousElemetPosition.width - currentElementFrame.width)/2
            case 2:
                x += (previousElemetPosition.width - currentElementFrame.width)/2
            case 3:
                x += -(previousElemetPosition.width - currentElementFrame.width)/2
            default:
                break
            }
        }
        return CGRect(x: x, y: y, width: currentElementFrame.width, height: currentElementFrame.height)
    }
}

extension NSImage {
    @objc var cgImage: CGImage? {
        get {
            guard let imageData = self.tiffRepresentation else { return nil }
            guard let sourceData = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
            return CGImageSourceCreateImageAtIndex(sourceData, 0, nil)
        }
    }
}
