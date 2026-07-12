import SwiftUI

/// A single text layer added on top of a photo. "Sticker" support comes
/// for free from plain text — the system keyboard's own emoji key lets the
/// user drop an emoji in, so there's no need for a separate bundled
/// sticker-art pipeline or picker UI just to place one on a photo.
struct PhotoOverlay: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var color: Color = .white
    var fontSize: CGFloat = 48
    var font: OverlayFont = .system
    /// Fixed black outline/shadow rather than a user-configurable color —
    /// keeps the edit sheet to a couple of toggles instead of two more
    /// color pickers, and a black outline/shadow is the near-universal
    /// default in every editor that has this (Picsart, Canva, etc.).
    var hasStroke = false
    var hasShadow = false
    /// Center point in the *overlay canvas's* own coordinate space (the
    /// GeometryReader in `OverlaysView`, sized to exactly the image's
    /// aspect ratio) — converted to the image's pixel space only once, at
    /// bake time, via `OverlayCompositor`, the same one-scale-factor
    /// approach `CropRotateView.finalImage()` uses.
    var position: CGPoint
}
