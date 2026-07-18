import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// A one-tap look applied over the current photo. Built entirely from
/// Core Image's built-in "photo effect" filters — fixed, parameterless
/// Apple presets, the same filters behind Photos' own filter picker — plus
/// two filters with a single, one-directional intensity (`CISepiaTone`,
/// and a hand-tuned "Vivid" via `CIColorControls`). Nothing here has a
/// sign/direction that could be guessed wrong without a real device to
/// check against, unlike e.g. a white-balance tint.
enum PhotoFilter: String, CaseIterable, Identifiable {
    case none
    case vivid
    case mono
    case noir
    case tonal
    case chrome
    case process
    case transfer
    case instant
    case fade
    case sepia
    case warm
    case cool
    case matte

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "Original"
        case .vivid: return "Vivid"
        case .mono: return "Mono"
        case .noir: return "Noir"
        case .tonal: return "Silvertone"
        case .chrome: return "Chrome"
        case .process: return "Process"
        case .transfer: return "Transfer"
        case .instant: return "Instant"
        case .fade: return "Fade"
        case .sepia: return "Sepia"
        case .warm: return "Warm"
        case .cool: return "Cool"
        case .matte: return "Matte"
        }
    }

    private static let context = CIContext()

    /// Renders this filter onto `image`. Returns `image` unchanged for
    /// `.none` rather than round-tripping it through Core Image for
    /// nothing.
    func apply(to image: UIImage) -> UIImage {
        guard self != .none, let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        let output: CIImage?

        switch self {
        case .none:
            output = ciImage
        case .vivid:
            let filter = CIFilter.colorControls()
            filter.inputImage = ciImage
            filter.saturation = 1.35
            filter.contrast = 1.12
            output = filter.outputImage
        case .mono:
            let filter = CIFilter.photoEffectMono()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .noir:
            let filter = CIFilter.photoEffectNoir()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .tonal:
            let filter = CIFilter.photoEffectTonal()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .chrome:
            let filter = CIFilter.photoEffectChrome()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .process:
            let filter = CIFilter.photoEffectProcess()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .transfer:
            let filter = CIFilter.photoEffectTransfer()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .instant:
            let filter = CIFilter.photoEffectInstant()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .fade:
            let filter = CIFilter.photoEffectFade()
            filter.inputImage = ciImage
            output = filter.outputImage
        case .sepia:
            let filter = CIFilter.sepiaTone()
            filter.inputImage = ciImage
            filter.intensity = 0.85
            output = filter.outputImage
        case .warm:
            // Per-channel gain via CIColorMatrix, diagonal only (each
            // output channel scales just its own input channel, like
            // Vivid's CIColorControls tweak above) — boosts red, trims
            // blue. A fixed one-directional preset, not a user-tunable
            // slider, so there's no sign to get backwards blind, same
            // reasoning as why Adjust has no temperature slider.
            let filter = CIFilter.colorMatrix()
            filter.inputImage = ciImage
            filter.rVector = CIVector(x: 1.12, y: 0, z: 0, w: 0)
            filter.gVector = CIVector(x: 0, y: 1.03, z: 0, w: 0)
            filter.bVector = CIVector(x: 0, y: 0, z: 0.85, w: 0)
            filter.biasVector = CIVector(x: 0.02, y: 0.01, z: 0, w: 0)
            output = filter.outputImage
        case .cool:
            let filter = CIFilter.colorMatrix()
            filter.inputImage = ciImage
            filter.rVector = CIVector(x: 0.90, y: 0, z: 0, w: 0)
            filter.gVector = CIVector(x: 0, y: 1.0, z: 0, w: 0)
            filter.bVector = CIVector(x: 0, y: 0, z: 1.14, w: 0)
            filter.biasVector = CIVector(x: 0, y: 0, z: 0.02, w: 0)
            output = filter.outputImage
        case .matte:
            // Faded, lifted-black look: desaturate/flatten contrast a
            // touch, then a tone curve that raises the shadow end (0 maps
            // to 0.08 instead of 0) and compresses the highlight end (1
            // maps to 0.92) — same five-point `CIToneCurve` shape
            // `PhotoAdjustments`' curve editor uses, just fixed here
            // instead of user-draggable.
            let colorControls = CIFilter.colorControls()
            colorControls.inputImage = ciImage
            colorControls.saturation = 0.85
            colorControls.contrast = 0.92
            if let base = colorControls.outputImage {
                let toneCurve = CIFilter.toneCurve()
                toneCurve.inputImage = base
                toneCurve.point0 = CGPoint(x: 0, y: 0.08)
                toneCurve.point1 = CGPoint(x: 0.25, y: 0.30)
                toneCurve.point2 = CGPoint(x: 0.5, y: 0.52)
                toneCurve.point3 = CGPoint(x: 0.75, y: 0.74)
                toneCurve.point4 = CGPoint(x: 1.0, y: 0.92)
                output = toneCurve.outputImage
            } else {
                output = nil
            }
        }

        // Extent, not `.zero`-origin image.size — none of these filters
        // shift the origin, but relying on that rather than assuming is
        // one less thing to get wrong blind.
        guard let output, let rendered = Self.context.createCGImage(output, from: ciImage.extent) else {
            return image
        }
        return UIImage(cgImage: rendered, scale: 1, orientation: .up)
    }
}
