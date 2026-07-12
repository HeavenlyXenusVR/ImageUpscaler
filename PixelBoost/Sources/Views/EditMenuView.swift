import SwiftUI

/// Dedicated home for every editing tool. These used to be crammed into a
/// horizontal scroll of small chips on the main screen — as more tools
/// shipped (five, now) that stopped scaling. Each tool gets its own card
/// here, and (Cutout aside, which is a single unattended action rather
/// than a screen) its own full-screen UI, opened one at a time from this
/// grid instead of everything competing for space on the primary Upscale
/// screen.
struct EditMenuView: View {
    @EnvironmentObject private var viewModel: UpscalerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isPresentingAdjustments = false
    @State private var isPresentingCropRotate = false
    @State private var isPresentingFilters = false
    @State private var isPresentingOverlays = false
    @State private var isPresentingInpaint = false

    private var currentImage: UIImage? {
        viewModel.resultImage ?? viewModel.sourceImage
    }

    private var isAnyToolRunning: Bool {
        viewModel.isUpscaling || viewModel.isComparing || viewModel.isRemovingBackground
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isRemovingBackground {
                        HStack(spacing: 8) {
                            ProgressView().tint(PBColor.accent)
                            Text("Finding the subject to cut out…")
                                .font(.system(size: 13))
                                .foregroundStyle(PBColor.inkDim)
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12.5))
                            .foregroundStyle(PBColor.bad)
                            .multilineTextAlignment(.center)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(EditTool.allCases) { tool in
                            toolCard(tool)
                        }
                    }
                }
                .padding(16)
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Edit Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .fullScreenCover(isPresented: $isPresentingAdjustments) {
                if let currentImage {
                    AdjustmentsView(image: currentImage) { viewModel.resultImage = $0 }
                }
            }
            .fullScreenCover(isPresented: $isPresentingCropRotate) {
                if let currentImage {
                    CropRotateView(image: currentImage) { viewModel.resultImage = $0 }
                }
            }
            .fullScreenCover(isPresented: $isPresentingFilters) {
                if let currentImage {
                    FiltersView(image: currentImage) { viewModel.resultImage = $0 }
                }
            }
            .fullScreenCover(isPresented: $isPresentingOverlays) {
                if let currentImage {
                    OverlaysView(image: currentImage) { viewModel.resultImage = $0 }
                }
            }
            .fullScreenCover(isPresented: $isPresentingInpaint) {
                if let currentImage {
                    InpaintView(image: currentImage) { viewModel.resultImage = $0 }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func toolCard(_ tool: EditTool) -> some View {
        Button {
            Haptics.lightImpact()
            switch tool {
            case .cutout: viewModel.removeBackground()
            case .adjust: isPresentingAdjustments = true
            case .crop: isPresentingCropRotate = true
            case .filters: isPresentingFilters = true
            case .overlays: isPresentingOverlays = true
            case .erase: isPresentingInpaint = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: tool.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(PBColor.accent)
                    .frame(width: 40, height: 40)
                    .background(PBColor.surface2, in: RoundedRectangle(cornerRadius: 11, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(PBColor.ink)
                    Text(tool.subtitle)
                        .font(.system(size: 11.5))
                        .foregroundStyle(PBColor.inkDim)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(PBColor.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(PBColor.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAnyToolRunning)
    }
}

private enum EditTool: String, CaseIterable, Identifiable {
    case cutout, adjust, crop, filters, overlays, erase

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cutout: return "Cutout"
        case .adjust: return "Adjust"
        case .crop: return "Crop & Rotate"
        case .filters: return "Filters"
        case .overlays: return "Overlays"
        case .erase: return "Erase"
        }
    }

    var subtitle: String {
        switch self {
        case .cutout: return "Remove the background"
        case .adjust: return "Brightness, contrast & more"
        case .crop: return "Crop and rotate"
        case .filters: return "One-tap looks"
        case .overlays: return "Text & stickers"
        case .erase: return "Paint away an object"
        }
    }

    var systemImage: String {
        switch self {
        case .cutout: return "scissors"
        case .adjust: return "slider.horizontal.3"
        case .crop: return "crop"
        case .filters: return "camera.filters"
        case .overlays: return "textformat"
        case .erase: return "eraser"
        }
    }
}

#Preview {
    let provider = UpscalerProvider()
    EditMenuView()
        .environmentObject(provider)
        .environmentObject(UpscalerViewModel(provider: provider))
}
