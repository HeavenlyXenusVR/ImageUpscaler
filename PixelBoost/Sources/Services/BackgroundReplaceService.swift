import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Places a curated fill (solid color, gradient, or a blurred copy of the
/// original photo) behind whatever transparency is already in the current
/// image — a Cutout result, typically. Deliberately **not** a generative
/// "replace the background with a new scene" model: a real one has the
/// same blind-conversion problem as the rest of this app's Core ML/GPU
/// work (see `RestoreService`'s face-restoration note for the same
/// reasoning), so this sticks to fills that are cheap, predictable, and
/// don't need a trained model at all.
enum BackgroundReplaceService {
    private static let context = CIContext()

    /// `subject` should already have real transparency (e.g. a Cutout
    /// result) — everywhere it's opaque, the fill is simply covered up.
    /// `original` is only used for `.blurredOriginal`; if it's `nil` (or
    /// has no `cgImage`), that case falls back to `.lightGray` instead of
    /// silently doing nothing.
    static func apply(_ fill: BackgroundFill, behind subject: UIImage, original: UIImage?) -> UIImage {
        guard let subjectCG = subject.cgImage else { return subject }
        let subjectCI = CIImage(cgImage: subjectCG)
        let background = backgroundImage(for: fill, extent: subjectCI.extent, original: original)

        // CISourceOverCompositing uses the top image's own alpha channel —
        // exactly what Cutout already produced — to decide how much of the
        // background shows through underneath.
        let composite = CIFilter.sourceOverCompositing()
        composite.inputImage = subjectCI
        composite.backgroundImage = background
        guard let output = composite.outputImage,
              let rendered = context.createCGImage(output, from: subjectCI.extent) else {
            return subject
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }

    private static func backgroundImage(for fill: BackgroundFill, extent: CGRect, original: UIImage?) -> CIImage {
        switch fill {
        case .white: return solidColor(UIColor(white: 0.97, alpha: 1), extent: extent)
        case .black: return solidColor(UIColor(white: 0.08, alpha: 1), extent: extent)
        case .lightGray: return solidColor(UIColor(white: 0.7, alpha: 1), extent: extent)
        case .skyBlue: return solidColor(UIColor(red: 0.53, green: 0.81, blue: 0.92, alpha: 1), extent: extent)
        case .sunset:
            return gradient(
                top: UIColor(red: 1, green: 0.6, blue: 0.4, alpha: 1),
                bottom: UIColor(red: 0.6, green: 0.2, blue: 0.5, alpha: 1),
                extent: extent
            )
        case .mint:
            return gradient(
                top: UIColor(red: 0.6, green: 0.95, blue: 0.85, alpha: 1),
                bottom: UIColor(red: 0.2, green: 0.6, blue: 0.55, alpha: 1),
                extent: extent
            )
        case .blurredOriginal:
            guard let original, let originalCG = original.cgImage else {
                return solidColor(UIColor(white: 0.7, alpha: 1), extent: extent)
            }
            let originalCI = CIImage(cgImage: originalCG)
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = originalCI.clampedToExtent()
            blur.radius = 30
            let blurred = blur.outputImage ?? originalCI
            // The original photo's own extent may not match the subject's
            // (e.g. after a crop) — scale it to cover before cropping to
            // the subject's extent, rather than assuming they line up.
            let scaleX = extent.width / originalCI.extent.width
            let scaleY = extent.height / originalCI.extent.height
            let scale = max(scaleX, scaleY)
            let scaled = blurred.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            return scaled.cropped(to: extent)
        }
    }

    private static func solidColor(_ color: UIColor, extent: CGRect) -> CIImage {
        CIImage(color: CIColor(cgColor: color.cgColor)).cropped(to: extent)
    }

    private static func gradient(top: UIColor, bottom: UIColor, extent: CGRect) -> CIImage {
        let filter = CIFilter.linearGradient()
        filter.point0 = CGPoint(x: extent.midX, y: extent.maxY)
        filter.point1 = CGPoint(x: extent.midX, y: extent.minY)
        filter.color0 = CIColor(cgColor: top.cgColor)
        filter.color1 = CIColor(cgColor: bottom.cgColor)
        return (filter.outputImage ?? CIImage(color: CIColor(cgColor: top.cgColor))).cropped(to: extent)
    }
}
