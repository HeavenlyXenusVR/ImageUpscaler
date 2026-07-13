import Social
import UIKit
import UniformTypeIdentifiers

/// The extension's whole UI — deliberately just the system-provided
/// compose sheet (`SLComposeServiceViewController`'s own screen: an image
/// preview strip, an optional text field we don't use, and Cancel/Post
/// buttons) rather than a custom storyboard/interface. There's no
/// device/simulator here to visually check a hand-built extension screen
/// on, so this leans entirely on Apple's standard, long-stable share-sheet
/// chrome instead.
final class ShareViewController: SLComposeServiceViewController {
    override func isContentValid() -> Bool {
        imageAttachment != nil
    }

    override func didSelectPost() {
        guard let imageAttachment else {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        imageAttachment.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { [weak self] item, _ in
            if let image = Self.image(from: item) {
                SharedPhotoBridge.savePendingImage(image)
            }
            self?.extensionContext?.completeRequest(returningItems: nil)
        }
    }

    override func configurationItems() -> [Any]! { [] }

    private var imageAttachment: NSItemProvider? {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem else { return nil }
        return item.attachments?.first { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }
    }

    private static func image(from item: NSSecureCoding?) -> UIImage? {
        if let url = item as? URL, let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        if let data = item as? Data {
            return UIImage(data: data)
        }
        return item as? UIImage
    }
}
