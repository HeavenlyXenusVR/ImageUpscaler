import UIKit

/// One finger-painted stroke — shared by every tool that paints a mask
/// (Object Removal's Erase, Selective Adjustments' region brush).
struct BrushStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var brushSize: CGFloat
}

/// Rasterizes a set of `BrushStroke`s (in canvas-space points) into a
/// black/white mask at a target pixel size, scaling from canvas
/// coordinates via a single uniform scale factor — safe wherever the
/// canvas is sized to exactly the target image's aspect ratio, which
/// every brush-painting tool in this app does.
enum BrushMask {
    static func rasterize(_ strokes: [BrushStroke], canvasSize: CGSize, pixelSize: CGSize) -> UIImage {
        let scale = pixelSize.width / canvasSize.width
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { rendererContext in
            UIColor.black.setFill()
            rendererContext.fill(CGRect(origin: .zero, size: pixelSize))

            let cgContext = rendererContext.cgContext
            cgContext.setStrokeColor(UIColor.white.cgColor)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)
            for stroke in strokes {
                guard let first = stroke.points.first else { continue }
                cgContext.setLineWidth(stroke.brushSize * scale)
                cgContext.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
                for point in stroke.points.dropFirst() {
                    cgContext.addLine(to: CGPoint(x: point.x * scale, y: point.y * scale))
                }
                cgContext.strokePath()
            }
        }
    }
}
