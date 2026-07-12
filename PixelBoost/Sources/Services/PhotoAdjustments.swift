import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Basic tonal adjustments — brightness/contrast/saturation (one filter,
/// `CIColorControls`) plus exposure (`CIExposureAdjust`). Deliberately
/// limited to these four: they're simple, well-defined, one-directional
/// controls with no ambiguity about which way "more" should look — unlike
/// e.g. a white-balance/temperature slider, which is easy to get backwards
/// without eyes on a real render to check against.
struct PhotoAdjustments: Equatable {
    /// Additive, roughly -1...1. 0 is unchanged.
    var brightness: Double = 0
    /// Multiplicative gain around the midpoint, roughly 0...2. 1 is unchanged.
    var contrast: Double = 1
    /// Multiplicative, roughly 0...2. 1 is unchanged, 0 is grayscale.
    var saturation: Double = 1
    /// EV stops, roughly -2...2. 0 is unchanged.
    var exposure: Double = 0

    static let identity = PhotoAdjustments()
    var isIdentity: Bool { self == .identity }

    private static let context = CIContext()

    /// Renders every non-default adjustment onto `image` in one pass.
    /// Returns `image` unchanged (no re-render) if nothing's been touched.
    func apply(to image: UIImage) -> UIImage {
        guard !isIdentity, let cgImage = image.cgImage else { return image }
        var ciImage = CIImage(cgImage: cgImage)

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = ciImage
        colorControls.brightness = Float(brightness)
        colorControls.contrast = Float(contrast)
        colorControls.saturation = Float(saturation)
        if let output = colorControls.outputImage {
            ciImage = output
        }

        if exposure != 0 {
            let exposureAdjust = CIFilter.exposureAdjust()
            exposureAdjust.inputImage = ciImage
            exposureAdjust.ev = Float(exposure)
            if let output = exposureAdjust.outputImage {
                ciImage = output
            }
        }

        // Extent, not `.zero`-origin image.size — CIColorControls/
        // CIExposureAdjust don't shift the origin, but relying on that
        // rather than assuming is one less thing to get wrong blind.
        guard let rendered = Self.context.createCGImage(ciImage, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }
}
