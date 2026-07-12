import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Basic tonal adjustments — brightness/contrast/saturation (one filter,
/// `CIColorControls`), exposure (`CIExposureAdjust`), and a tone curve
/// (`CIToneCurve`). Deliberately limited to these: they're simple,
/// well-defined, one-directional controls with no ambiguity about which
/// way "more" should look — unlike e.g. a white-balance/temperature
/// slider, which is easy to get backwards without eyes on a real render
/// to check against. The curve is likewise constrained on purpose — five
/// fixed input positions (0/0.25/0.5/0.75/1) you can only drag vertically
/// (see `CurveEditorView`), not a free-form point you could drag out of
/// order and get a curve that folds back on itself.
struct PhotoAdjustments: Equatable {
    /// Additive, roughly -1...1. 0 is unchanged.
    var brightness: Double = 0
    /// Multiplicative gain around the midpoint, roughly 0...2. 1 is unchanged.
    var contrast: Double = 1
    /// Multiplicative, roughly 0...2. 1 is unchanged, 0 is grayscale.
    var saturation: Double = 1
    /// EV stops, roughly -2...2. 0 is unchanged.
    var exposure: Double = 0
    /// Five output values (0...1) at fixed input positions 0, 0.25, 0.5,
    /// 0.75, 1 — `CIToneCurve`'s five control points. `identityCurve` (a
    /// straight diagonal, output == input) is the neutral/no-op shape.
    var curvePoints: [Double] = Self.identityCurve

    static let identityCurve: [Double] = [0, 0.25, 0.5, 0.75, 1]
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

        // Applied last — a tone curve is a final tonal remap on top of
        // whatever the sliders above already produced, the same order
        // most editors treat "curves" as a finishing step.
        if curvePoints != Self.identityCurve {
            let toneCurve = CIFilter.toneCurve()
            toneCurve.inputImage = ciImage
            toneCurve.point0 = CGPoint(x: 0, y: curvePoints[0])
            toneCurve.point1 = CGPoint(x: 0.25, y: curvePoints[1])
            toneCurve.point2 = CGPoint(x: 0.5, y: curvePoints[2])
            toneCurve.point3 = CGPoint(x: 0.75, y: curvePoints[3])
            toneCurve.point4 = CGPoint(x: 1.0, y: curvePoints[4])
            if let output = toneCurve.outputImage {
                ciImage = output
            }
        }

        // Extent, not `.zero`-origin image.size — none of these filters
        // shift the origin, but relying on that rather than assuming is
        // one less thing to get wrong blind.
        guard let rendered = Self.context.createCGImage(ciImage, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }
}
