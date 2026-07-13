import SwiftUI

/// Curated fills for Background Replace — deliberately not a generative
/// "AI background" model (see `BackgroundReplaceService`): solid colors, a
/// couple of two-stop gradients, and a blurred copy of the original photo
/// (a common "fake bokeh" trick every competitor app also ships alongside
/// its generative option).
enum BackgroundFill: String, CaseIterable, Identifiable, Equatable {
    case white, black, lightGray, skyBlue, sunset, mint, blurredOriginal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .white: return "White"
        case .black: return "Black"
        case .lightGray: return "Gray"
        case .skyBlue: return "Sky Blue"
        case .sunset: return "Sunset"
        case .mint: return "Mint"
        case .blurredOriginal: return "Blurred"
        }
    }

    /// Used for the picker swatch — gradients show both stops, the
    /// blurred option shows a neutral placeholder swatch since it depends
    /// on the actual photo rather than a fixed color.
    var swatchColors: [Color] {
        switch self {
        case .white: return [Color(white: 0.97)]
        case .black: return [Color(white: 0.08)]
        case .lightGray: return [Color(white: 0.7)]
        case .skyBlue: return [Color(red: 0.53, green: 0.81, blue: 0.92)]
        case .sunset: return [Color(red: 1, green: 0.6, blue: 0.4), Color(red: 0.6, green: 0.2, blue: 0.5)]
        case .mint: return [Color(red: 0.6, green: 0.95, blue: 0.85), Color(red: 0.2, green: 0.6, blue: 0.55)]
        case .blurredOriginal: return [Color(white: 0.5), Color(white: 0.6)]
        }
    }
}
