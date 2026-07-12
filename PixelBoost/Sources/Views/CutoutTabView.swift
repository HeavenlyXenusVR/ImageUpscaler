import SwiftUI

/// Cutout's own tab. Unlike the other five tools there's nothing to
/// adjust interactively (no sliders, crop handles, brush) — background
/// removal is a single unattended action — so this is a lighter screen:
/// a preview of the current photo, a one-line explanation, and a button.
/// Writes straight to `viewModel.resultImage`, same as every other tool.
struct CutoutTabView: View {
    @EnvironmentObject private var viewModel: UpscalerViewModel

    private var currentImage: UIImage? {
        viewModel.resultImage ?? viewModel.sourceImage
    }

    private var isAnyToolRunning: Bool {
        viewModel.isUpscaling || viewModel.isComparing || viewModel.isRemovingBackground
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                        Text("Cuts the main subject out of your photo with a transparent background, using on-device subject detection — the same technology behind Photos' \"Lift Subject.\"")
                            .font(.system(size: 13))
                            .foregroundStyle(PBColor.inkDim)
                            .multilineTextAlignment(.center)

                        Button {
                            Haptics.lightImpact()
                            viewModel.removeBackground()
                        } label: {
                            Label("Remove Background", systemImage: "scissors")
                        }
                        .buttonStyle(.pbGradient)
                        .disabled(isAnyToolRunning)

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
                    } else {
                        emptyState
                    }
                }
                .padding(20)
            }
            .background(PBColor.background.ignoresSafeArea())
            .navigationTitle("Cutout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(PBColor.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "scissors")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(PBColor.inkFaint)
            Text("Choose a photo on the Upscale tab first.")
                .font(.system(size: 13))
                .foregroundStyle(PBColor.inkDim)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
    }
}

#Preview {
    let provider = UpscalerProvider()
    CutoutTabView()
        .environmentObject(provider)
        .environmentObject(UpscalerViewModel(provider: provider))
}
