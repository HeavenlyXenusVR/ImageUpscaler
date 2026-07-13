import UIKit

extension UIImage {
    /// True if this image's pixel buffer actually carries an alpha
    /// channel — used both to decide export format (`PhotoLibrarySaver`'s
    /// Auto mode: PNG for real transparency, JPEG otherwise) and to detect
    /// "this looks like a Cutout result" (`CutoutTabView`'s Background
    /// Replace section only makes sense once there's transparency to fill).
    var hasAlphaChannel: Bool {
        let alphaInfo = cgImage?.alphaInfo ?? .none
        return ![.none, .noneSkipLast, .noneSkipFirst].contains(alphaInfo)
    }
}
