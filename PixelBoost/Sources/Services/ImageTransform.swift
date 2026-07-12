import CoreGraphics
import UIKit

/// Rotate/flip helpers for `CropRotateView` — crop itself reuses the
/// existing `UIImage.cropped(to:)` extension from `UIImage+Tile.swift`,
/// same top-left-origin pixel-rect convention.
///
/// Every renderer here uses `format.opaque = false` deliberately — these
/// tools chain onto whatever the current image already is (see
/// `UpscalerViewModel`'s `currentWorkingImage`), which after a Cutout run
/// has real transparency. An opaque render would silently flatten that to
/// black.
enum ImageTransform {
    static func rotated90(_ image: UIImage, clockwise: Bool) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let upright = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        let newSize = CGSize(width: image.size.height, height: image.size.width)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            context.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            // A CGContext inside UIGraphicsImageRenderer already matches
            // UIKit's own view coordinate space (Y down), where a positive
            // rotation angle appears clockwise on screen — the same
            // convention `CGAffineTransform(rotationAngle:)` uses for a
            // `UIView.transform`. If "rotate right" ever turns out to spin
            // the wrong way on a real device, flip the sign here first.
            context.cgContext.rotate(by: clockwise ? .pi / 2 : -.pi / 2)
            let drawRect = CGRect(
                x: -image.size.width / 2, y: -image.size.height / 2,
                width: image.size.width, height: image.size.height
            )
            upright.draw(in: drawRect)
        }
    }

    static func flippedHorizontally(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let upright = UIImage(cgImage: cgImage, scale: 1, orientation: .up)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            context.cgContext.translateBy(x: image.size.width, y: 0)
            context.cgContext.scaleBy(x: -1, y: 1)
            upright.draw(at: .zero)
        }
    }

    static func flippedVertically(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let upright = UIImage(cgImage: cgImage, scale: 1, orientation: .up)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { context in
            context.cgContext.translateBy(x: 0, y: image.size.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            upright.draw(at: .zero)
        }
    }
}
