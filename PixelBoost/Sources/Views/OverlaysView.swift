import SwiftUI

/// Add text (and, via the system keyboard's own emoji key, "stickers") on
/// top of a photo — drag to reposition, tap to edit or delete. Lives as
/// its own persistent tab (see `RootView`); there's deliberately no
/// pinch-resize or rotate gesture yet: text size and color are set in the
/// add/edit sheet instead of a live on-canvas transform. The same
/// reasoning `CropRotateView` gives for skipping corner-resize handles
/// applies doubly here, since a rotate gesture would also mean getting a
/// `CGContext` rotation sign right with no device to check it against —
/// so this ships the simpler, lower-risk version first. "Apply" bakes the
/// current overlays onto the shared result and clears the canvas for a
/// fresh layer; no dismiss step needed.
struct OverlaysView: View {
    @EnvironmentObject private var viewModel: UpscalerViewModel

    @State private var baseImage: UIImage?
    @State private var lastBase: UIImage?
    @State private var overlays: [PhotoOverlay] = []
    @State private var editingOverlay: PhotoOverlay?
    @State private var isAddingNew = false
    @State private var containerSize: CGSize = .zero
    @State private var dragStartPositions: [PhotoOverlay.ID: CGPoint] = [:]

    var body: some View {
        NavigationStack {
            Group {
                if let baseImage {
                    VStack(spacing: 16) {
                        GeometryReader { geo in
                            ZStack {
                                Image(uiImage: baseImage)
                                    .resizable()
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                ForEach(overlays) { overlay in
                                    overlayView(overlay, containerSize: geo.size)
                                }
                            }
                            .onAppear { containerSize = geo.size }
                            .onChange(of: geo.size) { _, newSize in containerSize = newSize }
                        }
                        .aspectRatio(baseImage.size, contentMode: .fit)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        Button {
                            Haptics.lightImpact()
                            isAddingNew = true
                        } label: {
                            Label("Add Text", systemImage: "textformat")
                        }
                        .buttonStyle(.pbGhost)
                        .padding(.horizontal, 20)

                        Button {
                            Haptics.lightImpact()
                            apply()
                        } label: {
                            Label("Apply", systemImage: "checkmark")
                        }
                        .buttonStyle(.pbGradient)
                        .disabled(overlays.isEmpty)
                        .padding(.horizontal, 20)

                        Spacer()
                    }
                } else {
                    emptyState
                }
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Overlays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: viewModel.imageVersion) { _, _ in refreshFromCurrentImage() }
            .onAppear { refreshFromCurrentImage() }
            .sheet(isPresented: $isAddingNew) {
                OverlayEditSheet(overlay: nil) { newOverlay in
                    var overlay = newOverlay
                    overlay.position = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2)
                    overlays.append(overlay)
                }
            }
            .sheet(isPresented: Binding(
                get: { editingOverlay != nil },
                set: { isPresented in if !isPresented { editingOverlay = nil } }
            )) {
                if let overlay = editingOverlay {
                    OverlayEditSheet(overlay: overlay, onDelete: {
                        overlays.removeAll { $0.id == overlay.id }
                    }) { updated in
                        if let index = overlays.firstIndex(where: { $0.id == overlay.id }) {
                            overlays[index] = updated
                        }
                    }
                }
            }
        }
    }

    /// Re-derives the canvas base from whichever photo is current, and
    /// clears in-progress overlays (they were positioned against the
    /// *previous* base, and after a successful `apply()` are already baked
    /// into the new one). Guarded by object identity (`!==`) so switching
    /// tabs back and forth without anything actually changing doesn't
    /// wipe an in-progress layer for nothing.
    private func refreshFromCurrentImage() {
        let current = viewModel.resultImage ?? viewModel.sourceImage
        guard let current else {
            lastBase = nil
            baseImage = nil
            overlays = []
            return
        }
        guard current !== lastBase else { return }
        lastBase = current
        baseImage = current
        overlays = []
    }

    /// Bakes the current overlays onto `baseImage` and writes back to the
    /// shared result — which will itself bump `imageVersion` and trigger
    /// `refreshFromCurrentImage()`, clearing the canvas for a fresh layer
    /// on its own.
    private func apply() {
        guard !overlays.isEmpty, let baseImage, containerSize.width > 0 else { return }
        viewModel.resultImage = OverlayCompositor.render(overlays: overlays, onto: baseImage, canvasSize: containerSize)
    }

    private func overlayView(_ overlay: PhotoOverlay, containerSize: CGSize) -> some View {
        Text(overlay.text)
            .font(.system(size: overlay.fontSize))
            .foregroundStyle(overlay.color)
            .fixedSize()
            .position(overlay.position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard let index = overlays.firstIndex(where: { $0.id == overlay.id }) else { return }
                        let start = dragStartPositions[overlay.id] ?? overlay.position
                        if dragStartPositions[overlay.id] == nil { dragStartPositions[overlay.id] = overlay.position }
                        var newPosition = CGPoint(
                            x: start.x + value.translation.width,
                            y: start.y + value.translation.height
                        )
                        newPosition.x = max(0, min(newPosition.x, containerSize.width))
                        newPosition.y = max(0, min(newPosition.y, containerSize.height))
                        overlays[index].position = newPosition
                    }
                    .onEnded { _ in dragStartPositions[overlay.id] = nil }
            )
            .onTapGesture { editingOverlay = overlay }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "textformat")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(PBColor.inkFaint)
            Text("Choose a photo on the Upscale tab first.")
                .font(.system(size: 13))
                .foregroundStyle(PBColor.inkDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    let provider = UpscalerProvider()
    OverlaysView()
        .environmentObject(provider)
        .environmentObject(UpscalerViewModel(provider: provider))
}
