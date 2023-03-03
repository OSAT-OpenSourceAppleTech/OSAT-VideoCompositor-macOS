//
//  OSATAnnotation.swift
//  OSAT-VideoCompositor-macOS
//
//  Created by snbehar on 09/02/23.
//

import AVFoundation

/// OSATWaterMarkPosition describes where we can align the text in the video frame.
public enum OSATWaterMarkPosition {
    case LeftBottomCorner
    case RightBottomCorner
    case LeftTopCorner
    case RightTopCorner
}

/// OSATAnnotationProtocol  is a base protocol for all Annotation object layers supported by OSAT-VideoCompositor
public protocol OSATAnnotationProtocol {
    var timeRange: CMTimeRange? { get }
    var frame: NSRect { get }
    func getAnnotationLayer() -> CALayer
}

/// OSATImageAnnotation holds data for  the image annotation to be rendered on Video
public struct OSATImageAnnotation: OSATAnnotationProtocol {
    let image: NSImage
    public let frame: NSRect
    
    public let timeRange: CMTimeRange?
    
    public init(image: NSImage, frame: NSRect, timeRange: CMTimeRange?) {
        self.image = image
        self.frame = frame
        self.timeRange = timeRange
    }
    
    public func getAnnotationLayer() -> CALayer {
        let imageLayer = CALayer()
        imageLayer.frame = frame
        imageLayer.contents = image.cgImage
        return imageLayer
    }
}


/// OSATTextAnnotation holds data for the text annotation to be rendered on Video
public struct OSATTextAnnotation: OSATAnnotationProtocol {
    let text: String
    public let frame: NSRect
    let attributedText: NSAttributedString?
    let textColor: NSColor?
    let backgroundColor: NSColor?
    let font: NSFont?
    
    public let timeRange: CMTimeRange?
    
    public init(text: String, frame: NSRect, timeRange: CMTimeRange?, attributedText: NSAttributedString?, textColor: NSColor?, backgroundColor: NSColor?, font: NSFont?) {
        self.text = text
        self.frame = frame
        self.timeRange = timeRange
        self.attributedText = attributedText
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.font = font
    }

    public func getAnnotationLayer() -> CALayer {
        let textLayer = CATextLayer()
        textLayer.string = attributedText ?? text
        textLayer.font = font
        textLayer.fontSize = font?.pointSize ?? 12
        textLayer.foregroundColor = textColor?.cgColor ?? .white
        textLayer.backgroundColor = backgroundColor?.cgColor
        textLayer.frame = frame

        textLayer.shouldRasterize = true
        textLayer.rasterizationScale = NSScreen.main?.backingScaleFactor ?? 1
        textLayer.displayIfNeeded()
        return textLayer
    }
}


/// OSATBezierAnnotation holds data for the Bezier sPath annotation to be rendered on Video
public struct OSATBezierAnnotation: OSATAnnotationProtocol {
    let bezierPath: NSBezierPath
    let position: NSPoint
    let lineWidth: CGFloat
    let strokeColor: NSColor?
    let fillColor: NSColor?
    
    public let frame: NSRect
    public let timeRange: CMTimeRange?
    
    public init(bezierPath: NSBezierPath, position: NSPoint, lineWidth: CGFloat, timeRange: CMTimeRange, strokeColor: NSColor?, fillColor: NSColor?, frame: NSRect) {
        self.bezierPath = bezierPath
        self.position = position
        self.lineWidth = lineWidth
        self.timeRange = timeRange
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.frame = frame
    }
    
    public func getAnnotationLayer() -> CALayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = frame
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.position = position
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor?.cgColor
        shapeLayer.fillColor = strokeColor?.cgColor
        return shapeLayer
    }
}

extension NSBezierPath {

    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)

        for i in 0 ..< elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                continue
            }
        }

        return path
    }
}
