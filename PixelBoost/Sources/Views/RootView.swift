import SwiftUI

/// App root: every tab's content stays mounted the whole time (toggled
/// with opacity/hit-testing, never removed from the tree) so switching
/// tabs never loses in-progress state — crop selection, paint strokes,
/// slider positions, whatever a tab was in the middle of. That's the
/// tradeoff for a custom scrollable bar instead of a native `TabView`
/// (which would do this for free, but only for ~5 tabs before collapsing
/// the rest into "More" — not workable for a dozen tabs).
struct RootView: View {
    @EnvironmentObject private var provider: UpscalerProvider
    @EnvironmentObject private var viewModel: UpscalerViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                tabContent(tab)
                    .opacity(selectedTab == tab ? 1 : 0)
                    .allowsHitTesting(selectedTab == tab)
                    .zIndex(selectedTab == tab ? 1 : 0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .preferredColorScheme(.dark)
        .onAppear { consumeSharedPhotoIfNeeded() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { consumeSharedPhotoIfNeeded() }
        }
    }

    /// The Share Extension runs in a separate process and can only drop a
    /// photo into a shared App Group container (see `SharedPhotoBridge`) —
    /// this is the main app's side of that hand-off, checked on launch and
    /// every time the app comes back to the foreground (covers both "share
    /// into PixelBoost while it's not running" and "share while it's
    /// already open in the background").
    private func consumeSharedPhotoIfNeeded() {
        guard let image = SharedPhotoBridge.consumePendingImage() else { return }
        viewModel.loadSharedImage(image)
        selectedTab = .home
    }

    @ViewBuilder
    private func tabContent(_ tab: AppTab) -> some View {
        switch tab {
        case .home: ContentView()
        case .cutout: CutoutTabView()
        case .enhance: AutoEnhanceView()
        case .adjust: AdjustmentsView()
        case .selective: SelectiveAdjustView()
        case .crop: CropRotateView()
        case .filters: FiltersView()
        case .overlays: OverlaysView()
        case .erase: InpaintView()
        case .restore: RestoreView()
        case .clone: CloneStampView()
        case .batch: NavigationStack { BatchUpscaleView(provider: provider) }
        case .cloud: NavigationStack { CloudView() }
        case .history: NavigationStack { HistoryView() }
        case .settings: NavigationStack { SettingsView() }
        }
    }

    private var bottomBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(AppTab.allCases) { tab in
                    tabButton(tab)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 60)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(PBColor.line).frame(height: 1)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            Haptics.lightImpact()
            selectedTab = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 9.5, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? PBColor.accent : PBColor.inkDim)
            .frame(width: 64)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let provider = UpscalerProvider()
    RootView()
        .environmentObject(provider)
        .environmentObject(UpscalerViewModel(provider: provider))
}
