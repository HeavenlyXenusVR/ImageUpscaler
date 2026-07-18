import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// A single edge-crispness pass over a whole image, run *after* upscaling
/// finishes (see `UpscaleRunner`) — same `CISharpenLuminance` filter
/// `RestoreService.restoreFaces` already uses over just its face mask, here
/// applied over the full frame instead.
enum PostSharpen {
    private static let context = CIContext()

    /// `amount` 0...1 — scales `CISharpenLuminance`'s `sharpness` input.
    /// 0 returns `image` unchanged with no re-render.
    static func apply(_ image: UIImage, amount: Double) -> UIImage {
        guard amount > 0, let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)

        let filter = CIFilter.sharpenLuminance()
        filter.inputImage = ciImage
        filter.sharpness = Float(amount * 1.2)

        guard let output = filter.outputImage,
              let rendered = context.createCGImage(output, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }
}
