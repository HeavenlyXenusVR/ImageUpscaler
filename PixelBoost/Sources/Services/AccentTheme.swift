import SwiftUI

/// A curated accent-color choice for `PBColor.accent`/`accent2` — Settings
/// lets you pick one of these instead of the app being permanently locked
/// to blue. Each case ships its own two-color gradient pair (not a derived
/// lighter/darker shade computed from one base color) so every combination
/// is something actually chosen and looked at, rather than trusting HSB
/// math to produce a good-looking pair blind.
///
/// **Applies at next launch, not live.** `PBColor.accent` (see `Theme.swift`)
/// reads this once via a `static let`, evaluated the first time any view
/// touches `PBColor` — for all practical purposes, app launch. Threading a
/// live color change through every already-mounted tab would mean forcing
/// the whole view tree to recreate (e.g. an `.id()` change on `RootView`'s
/// root), which would also wipe every tab's in-progress state (crop
/// selection, paint strokes, slider positions) — exactly what `RootView`'s
/// permanent-mount design was built to avoid. Settings documents this
/// plainly rather than silently only-sometimes-working.
enum AccentTheme: String, CaseIterable, Identifiable {
    case blue, purple, teal, pink, orange, green, red, graphite

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .teal: return "Teal"
        case .pink: return "Pink"
        case .orange: return "Orange"
        case .green: return "Green"
        case .red: return "Red"
        case .graphite: return "Graphite"
        }
    }

    /// The original app accent, `#1673EC`.
    var primary: Color {
        switch self {
        case .blue: return Color(red: 0.239, green: 0.545, blue: 1.0)
        case .purple: return Color(red: 0.545, green: 0.420, blue: 1.0)
        case .teal: return Color(red: 0.161, green: 0.729, blue: 0.686)
        case .pink: return Color(red: 1.0, green: 0.361, blue: 0.616)
        case .orange: return Color(red: 1.0, green: 0.573, blue: 0.204)
        case .green: return Color(red: 0.298, green: 0.788, blue: 0.427)
        case .red: return Color(red: 0.937, green: 0.298, blue: 0.298)
        case .graphite: return Color(red: 0.643, green: 0.667, blue: 0.710)
        }
    }

    /// Gradient partner for `primary`, used by `PBColor.accentGradient`.
    var secondary: Color {
        switch self {
        case .blue: return Color(red: 0.545, green: 0.420, blue: 1.0)
        case .purple: return Color(red: 0.816, green: 0.400, blue: 0.937)
        case .teal: return Color(red: 0.298, green: 0.788, blue: 0.596)
        case .pink: return Color(red: 1.0, green: 0.478, blue: 0.420)
        case .orange: return Color(red: 1.0, green: 0.784, blue: 0.298)
        case .green: return Color(red: 0.298, green: 0.729, blue: 0.686)
        case .red: return Color(red: 0.937, green: 0.420, blue: 0.545)
        case .graphite: return Color(red: 0.843, green: 0.859, blue: 0.882)
        }
    }
}
