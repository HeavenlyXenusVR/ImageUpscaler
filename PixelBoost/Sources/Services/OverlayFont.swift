import SwiftUI
import UIKit

/// A curated set of fonts genuinely bundled with iOS — no custom font
/// files/`UIAppFonts` entries needed. PostScript names for a couple of the
/// more decorative ones (`.markerFelt`, `.noteworthy`) are the least
/// certain of the set with no device to double-check against; `uiFont`/
/// `font` both fall back to the plain system font rather than a crash or
/// a silently-blank label if a name is ever wrong on some iOS version.
enum OverlayFont: String, CaseIterable, Identifiable {
    case system
    case helveticaNeue
    case georgia
    case courier
    case americanTypewriter
    case snellRoundhand
    case markerFelt
    case noteworthy

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .helveticaNeue: return "Helvetica"
        case .georgia: return "Georgia"
        case .courier: return "Courier"
        case .americanTypewriter: return "Typewriter"
        case .snellRoundhand: return "Script"
        case .markerFelt: return "Marker"
        case .noteworthy: return "Noteworthy"
        }
    }

    private var postScriptName: String? {
        switch self {
        case .system: return nil
        case .helveticaNeue: return "HelveticaNeue"
        case .georgia: return "Georgia"
        case .courier: return "Courier"
        case .americanTypewriter: return "AmericanTypewriter"
        case .snellRoundhand: return "SnellRoundhand"
        case .markerFelt: return "MarkerFelt-Wide"
        case .noteworthy: return "Noteworthy-Bold"
        }
    }

    /// For `OverlayCompositor`'s bake step (`NSAttributedString` needs a
    /// real `UIFont`).
    func uiFont(size: CGFloat) -> UIFont {
        guard let postScriptName, let font = UIFont(name: postScriptName, size: size) else {
            return UIFont.systemFont(ofSize: size, weight: .semibold)
        }
        return font
    }

    /// For the live on-canvas SwiftUI preview in `OverlaysView`.
    func font(size: CGFloat) -> Font {
        guard let postScriptName else { return .system(size: size, weight: .semibold) }
        return .custom(postScriptName, size: size)
    }
}
