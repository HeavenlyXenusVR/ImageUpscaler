import SwiftUI

/// Brightness/contrast/saturation/exposure sliders with a live preview.
/// The preview renders against a downscaled copy of `image` (recomputing a
/// full-resolution photo on every slider tick would be far too slow to
/// feel live) — the full-resolution version only gets rendered once, on
/// "Done".
struct AdjustmentsView: View {
    let image: UIImage
    let onDone: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var adjustments = PhotoAdjustments()
    @State private var previewImage: UIImage
    private let previewSource: UIImage

    init(image: UIImage, onDone: @escaping (UIImage) -> Void) {
        self.image = image
        self.onDone = onDone
        let preview = Self.downscaled(image, maxDimension: 800)
        previewSource = preview
        _previewImage = State(initialValue: preview)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                VStack(spacing: 18) {
                    HStack {
                        Text("Adjustments")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.4)
                            .foregroundStyle(PBColor.inkFaint)
                        Spacer()
                        Button("Reset") { adjustments = .identity }
                            .font(.system(size: 13, weight: .semibold))
                            .disabled(adjustments.isIdentity)
                    }
                    adjustmentSlider("Brightness", value: $adjustments.brightness, range: -0.5...0.5)
                    adjustmentSlider("Contrast", value: $adjustments.contrast, range: 0.5...1.5)
                    adjustmentSlider("Saturation", value: $adjustments.saturation, range: 0...2)
                    adjustmentSlider("Exposure", value: $adjustments.exposure, range: -1.5...1.5)
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Adjust")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(adjustments.apply(to: image))
                        dismiss()
                    }
                    .disabled(adjustments.isIdentity)
                    .fontWeight(.bold)
                }
            }
            .onChange(of: adjustments) { _, newValue in
                previewImage = newValue.apply(to: previewSource)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func adjustmentSlider(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(PBColor.ink)
            Slider(value: value, in: range)
                .tint(PBColor.accent)
        }
    }

    private static func downscaled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let scale = min(1, maxDimension / max(image.size.width, image.size.height))
        guard scale < 1 else { return image }
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

#Preview {
    AdjustmentsView(image: UIImage(systemName: "photo")!) { _ in }
}
