import SwiftUI

/// Add text (and, via the system keyboard's own emoji key, "stickers") on
/// top of a photo — drag to reposition, tap to edit or delete. There's
/// deliberately no pinch-resize or rotate gesture yet: text size and color
/// are set in the add/edit sheet instead of a live on-canvas transform.
/// The same reasoning `CropRotateView` gives for skipping corner-resize
/// handles applies doubly here, since a rotate gesture would also mean
/// getting a `CGContext` rotation sign right with no device to check it
/// against — so this ships the simpler, lower-risk version first.
struct OverlaysView: View {
    let image: UIImage
    let onDone: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var overlays: [PhotoOverlay] = []
    @State private var editingOverlay: PhotoOverlay?
    @State private var isAddingNew = false
    @State private var containerSize: CGSize = .zero
    @State private var dragStartPositions: [PhotoOverlay.ID: CGPoint] = [:]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                GeometryReader { geo in
                    ZStack {
                        Image(uiImage: image)
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
                .aspectRatio(image.size, contentMode: .fit)
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

                Spacer()
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Overlays")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDone(OverlayCompositor.render(overlays: overlays, onto: image, canvasSize: containerSize))
                        dismiss()
                    }
                    .disabled(overlays.isEmpty)
                    .fontWeight(.bold)
                }
            }
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
        .preferredColorScheme(.dark)
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
}

#Preview {
    OverlaysView(image: UIImage(systemName: "photo")!) { _ in }
}
