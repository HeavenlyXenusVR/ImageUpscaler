import UIKit

/// Corner (or center) a text watermark is drawn in — see `Watermark.apply`.
enum WatermarkPosition: String, CaseIterable, Identifiable {
    case bottomRight, bottomLeft, topRight, topLeft, center

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bottomRight: return "Bottom Right"
        case .bottomLeft: return "Bottom Left"
        case .topRight: return "Top Right"
        case .topLeft: return "Top Left"
        case .center: return "Center"
        }
    }
}

/// Draws a plain text watermark onto a copy of an image at save time — a
/// signature/credit line, not a copy-protection measure (nothing here
/// resists cropping or content-aware removal). Deliberately plain UIKit
/// text drawing, the same `NSAttributedString.draw(at:)` approach
/// `OverlayCompositor` already uses for baked overlay text, rather than a
/// new drawing path.
enum Watermark {
    static func apply(text: String, position: WatermarkPosition, opacity: Double, to image: UIImage) -> UIImage {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, opacity > 0 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))

            // Scaled off image width so the watermark stays legible (and
            // proportionally sized) whether it's landing on a 500px photo
            // or a 4x-upscaled 8000px one.
            let fontSize = max(14, image.size.width * 0.022)
            let font = UIFont.boldSystemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(opacity),
                // Negative width draws fill+stroke together, same trick
                // OverlayCompositor uses, so the text stays legible over
                // both light and dark backgrounds.
                .strokeColor: UIColor.black.withAlphaComponent(opacity * 0.7),
                .strokeWidth: -3.0,
            ]
            let string = trimmed as NSString
            let textSize = string.size(withAttributes: attributes)
            let margin = max(8, image.size.width * 0.02)

            let origin: CGPoint
            switch position {
            case .bottomRight:
                origin = CGPoint(x: image.size.width - textSize.width - margin, y: image.size.height - textSize.height - margin)
            case .bottomLeft:
                origin = CGPoint(x: margin, y: image.size.height - textSize.height - margin)
            case .topRight:
                origin = CGPoint(x: image.size.width - textSize.width - margin, y: margin)
            case .topLeft:
                origin = CGPoint(x: margin, y: margin)
            case .center:
                origin = CGPoint(x: (image.size.width - textSize.width) / 2, y: (image.size.height - textSize.height) / 2)
            }
            string.draw(at: origin, withAttributes: attributes)
        }
    }
}
