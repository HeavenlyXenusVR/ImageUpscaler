import UIKit

/// Bakes a set of text overlays onto a full-resolution image. Deliberately
/// translate-only, no rotation — see `OverlaysView`'s doc comment for why —
/// so this only needs to scale each overlay's canvas-space position/font
/// size into the image's pixel space and draw it, with no transform sign
/// that could be guessed wrong blind.
enum OverlayCompositor {
    static func render(overlays: [PhotoOverlay], onto image: UIImage, canvasSize: CGSize) -> UIImage {
        guard !overlays.isEmpty, canvasSize.width > 0, canvasSize.height > 0 else { return image }
        // Single uniform scale factor — safe because the canvas is always
        // sized to exactly the image's aspect ratio, so there's no
        // letterboxing to account for.
        let scaleFactor = image.size.width / canvasSize.width

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            for overlay in overlays {
                let font = UIFont.systemFont(ofSize: overlay.fontSize * scaleFactor)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor(overlay.color),
                ]
                let string = overlay.text as NSString
                let textSize = string.size(withAttributes: attributes)
                let origin = CGPoint(
                    x: overlay.position.x * scaleFactor - textSize.width / 2,
                    y: overlay.position.y * scaleFactor - textSize.height / 2
                )
                string.draw(at: origin, withAttributes: attributes)
            }
        }
    }
}
