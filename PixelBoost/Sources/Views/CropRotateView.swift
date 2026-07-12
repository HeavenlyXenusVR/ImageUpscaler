import SwiftUI

/// Fixed-aspect-ratio crop — pick a ratio, drag the resulting window to
/// reposition — plus 90-degree rotate. Deliberately no corner-resize
/// handles or free-angle straighten in this first pass: that gesture math
/// is easy to get subtly wrong, and there's no way to visually verify it
/// in this environment, so this starts with the simpler, lower-risk
/// version (a fixed-size window you can slide) rather than a fragile
/// full-featured one.
struct CropRotateView: View {
    let onDone: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var workingImage: UIImage
    @State private var selectedRatio: CropRatio?
    @State private var cropRect: CGRect = .zero
    @State private var containerSize: CGSize = .zero
    @State private var dragStartOrigin: CGPoint?

    init(image: UIImage, onDone: @escaping (UIImage) -> Void) {
        self.onDone = onDone
        _workingImage = State(initialValue: image)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: workingImage)
                            .resizable()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        if selectedRatio != nil {
                            cropOverlay(containerSize: geo.size)
                        }
                    }
                    .onAppear { containerSize = geo.size }
                    .onChange(of: geo.size) { _, newSize in containerSize = newSize }
                    .onChange(of: selectedRatio) { _, newRatio in
                        if let newRatio {
                            cropRect = Self.maxRect(for: newRatio.value, in: geo.size)
                        }
                    }
                }
                .aspectRatio(workingImage.size, contentMode: .fit)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                HStack(spacing: 10) {
                    toolButton("rotate.left") { rotate(clockwise: false) }
                    toolButton("rotate.right") { rotate(clockwise: true) }
                }

                ratioChipsRow

                Spacer()
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Crop & Rotate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(finalImage())
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toolButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PBColor.ink)
                .frame(width: 44, height: 44)
                .background(PBColor.surface2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var ratioChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ratioChip(title: "Free", isSelected: selectedRatio == nil) { selectedRatio = nil }
                ForEach(CropRatio.allCases) { ratio in
                    ratioChip(title: ratio.label, isSelected: selectedRatio == ratio) { selectedRatio = ratio }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func ratioChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isSelected ? .white : PBColor.inkDim)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? AnyShapeStyle(PBColor.accentGradient) : AnyShapeStyle(PBColor.surface2),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    private func cropOverlay(containerSize: CGSize) -> some View {
        Rectangle()
            .fill(PBColor.accent.opacity(0.15))
            .overlay(Rectangle().strokeBorder(PBColor.accentGradient, lineWidth: 2))
            .frame(width: cropRect.width, height: cropRect.height)
            .position(x: cropRect.midX, y: cropRect.midY)
            .contentShape(Rectangle())
            .gesture(panGesture(containerSize: containerSize))
    }

    private func panGesture(containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let startOrigin = dragStartOrigin ?? cropRect.origin
                if dragStartOrigin == nil { dragStartOrigin = cropRect.origin }
                var newOrigin = CGPoint(
                    x: startOrigin.x + value.translation.width,
                    y: startOrigin.y + value.translation.height
                )
                newOrigin.x = max(0, min(newOrigin.x, containerSize.width - cropRect.width))
                newOrigin.y = max(0, min(newOrigin.y, containerSize.height - cropRect.height))
                cropRect.origin = newOrigin
            }
            .onEnded { _ in dragStartOrigin = nil }
    }

    private func rotate(clockwise: Bool) {
        workingImage = ImageTransform.rotated90(workingImage, clockwise: clockwise)
        // The old crop window was sized/positioned for the previous
        // aspect ratio — rather than trying to remap it, drop back to
        // Free and let the user re-pick a ratio against the new shape.
        selectedRatio = nil
    }

    /// Converts `cropRect` from on-screen display coordinates back to
    /// `workingImage`'s own pixel coordinates using a single uniform scale
    /// factor — safe because the container is always sized to exactly
    /// `workingImage`'s aspect ratio (`.aspectRatio(workingImage.size,
    /// contentMode: .fit)`), so there's no letterboxing to account for.
    private func finalImage() -> UIImage {
        guard selectedRatio != nil, containerSize.width > 0, containerSize.height > 0 else { return workingImage }
        let scale = workingImage.size.width / containerSize.width
        let pixelRect = CGRect(
            x: cropRect.origin.x * scale, y: cropRect.origin.y * scale,
            width: cropRect.width * scale, height: cropRect.height * scale
        )
        return workingImage.cropped(to: pixelRect)
    }

    private static func maxRect(for ratio: CGFloat, in container: CGSize) -> CGRect {
        var size = CGSize(width: container.width, height: container.width / ratio)
        if size.height > container.height {
            size = CGSize(width: container.height * ratio, height: container.height)
        }
        let origin = CGPoint(x: (container.width - size.width) / 2, y: (container.height - size.height) / 2)
        return CGRect(origin: origin, size: size)
    }
}

private enum CropRatio: CaseIterable, Identifiable {
    case square, portrait45, landscape54, landscape169, portrait916

    var id: Self { self }

    var label: String {
        switch self {
        case .square: return "1:1"
        case .portrait45: return "4:5"
        case .landscape54: return "5:4"
        case .landscape169: return "16:9"
        case .portrait916: return "9:16"
        }
    }

    /// Width ÷ height.
    var value: CGFloat {
        switch self {
        case .square: return 1
        case .portrait45: return 4.0 / 5.0
        case .landscape54: return 5.0 / 4.0
        case .landscape169: return 16.0 / 9.0
        case .portrait916: return 9.0 / 16.0
        }
    }
}

#Preview {
    CropRotateView(image: UIImage(systemName: "photo")!) { _ in }
}
