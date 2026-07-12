import SwiftUI

/// Add or edit a single text overlay's content, color, and size — shown
/// from `OverlaysView` both for placing a brand-new overlay (`overlay ==
/// nil`) and for editing/deleting one already on the canvas.
struct OverlayEditSheet: View {
    let overlay: PhotoOverlay?
    var onDelete: (() -> Void)?
    let onSave: (PhotoOverlay) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var color: Color
    @State private var fontSize: Double
    @State private var font: OverlayFont
    @State private var hasStroke: Bool
    @State private var hasShadow: Bool

    init(overlay: PhotoOverlay?, onDelete: (() -> Void)? = nil, onSave: @escaping (PhotoOverlay) -> Void) {
        self.overlay = overlay
        self.onDelete = onDelete
        self.onSave = onSave
        _text = State(initialValue: overlay?.text ?? "")
        _color = State(initialValue: overlay?.color ?? .white)
        _fontSize = State(initialValue: Double(overlay?.fontSize ?? 48))
        _font = State(initialValue: overlay?.font ?? .system)
        _hasStroke = State(initialValue: overlay?.hasStroke ?? false)
        _hasShadow = State(initialValue: overlay?.hasShadow ?? false)
    }

    private var isNew: Bool { overlay == nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Text or emoji", text: $text)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 20))
                    Text("Tip: use your keyboard's emoji key to drop in a sticker.")
                        .font(.system(size: 11.5))
                        .foregroundStyle(PBColor.inkFaint)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ColorPicker("Color", selection: $color)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Size")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PBColor.ink)
                    Slider(value: $fontSize, in: 20...160)
                        .tint(PBColor.accent)
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Font")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PBColor.ink)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(OverlayFont.allCases) { option in
                                fontChip(option)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                VStack(spacing: 10) {
                    Toggle("Outline", isOn: $hasStroke)
                    Toggle("Shadow", isOn: $hasShadow)
                }
                .tint(PBColor.accent)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(PBColor.ink)
                .padding(.horizontal, 20)

                if let onDelete {
                    Button(role: .destructive) {
                        onDelete()
                        dismiss()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.pbGhost)
                    .padding(.horizontal, 20)
                }

                Spacer()
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle(isNew ? "Add Text" : "Edit Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Add" : "Save") {
                        var result = overlay ?? PhotoOverlay(text: "", position: .zero)
                        result.text = text
                        result.color = color
                        result.fontSize = CGFloat(fontSize)
                        result.font = font
                        result.hasStroke = hasStroke
                        result.hasShadow = hasShadow
                        onSave(result)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func fontChip(_ option: OverlayFont) -> some View {
        let isSelected = font == option
        return Button {
            font = option
        } label: {
            Text("Aa")
                .font(option.font(size: 20))
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
}

#Preview {
    OverlayEditSheet(overlay: nil) { _ in }
}
