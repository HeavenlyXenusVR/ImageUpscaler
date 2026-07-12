import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Applies `PhotoAdjustments` only inside a painted mask, blending the
/// adjusted version back over the untouched original everywhere else —
/// the same `CIBlendWithMask` compositing `BackgroundRemovalService` and
/// `InpaintingService` already use, just with "an adjusted copy of the
/// same photo" as the foreground instead of a cutout subject or a
/// diffusion fill.
enum SelectiveAdjustmentService {
    private static let context = CIContext()

    static func apply(_ adjustments: PhotoAdjustments, to image: UIImage, maskedBy maskImage: UIImage) -> UIImage {
        guard !adjustments.isIdentity else { return image }
        let adjusted = adjustments.apply(to: image)
        guard let adjustedCG = adjusted.cgImage, let originalCG = image.cgImage, let maskCG = maskImage.cgImage else {
            return adjusted
        }

        let foreground = CIImage(cgImage: adjustedCG)
        let background = CIImage(cgImage: originalCG)
        let mask = CIImage(cgImage: maskCG)

        let blend = CIFilter.blendWithMask()
        blend.inputImage = foreground
        blend.backgroundImage = background
        blend.maskImage = mask
        guard let output = blend.outputImage,
              let rendered = context.createCGImage(output, from: background.extent) else {
            return adjusted
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }
}
