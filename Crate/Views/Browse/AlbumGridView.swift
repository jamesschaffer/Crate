import SwiftUI

/// Infinite-scroll grid of album cover tiles.
///
/// Always displays as edge-to-edge artwork wall (no spacing, no text labels).
/// When the user scrolls near the bottom, triggers onLoadMore to fetch the next page.
struct AlbumGridView: View {

    let albums: [CrateAlbum]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    var topInset: CGFloat = 0
    var scrollToTopTrigger: Bool = false
    var gridContext: [CrateAlbum]?

    private var columns: [GridItem] {
        #if os(iOS)
        return [
            GridItem(.flexible(), spacing: 0),
            GridItem(.flexible(), spacing: 0),
        ]
        #else
        return [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 0)]
        #endif
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 0)
                        .id("grid-top")

                    Color.black
                        .frame(height: topInset)

                    LazyVGrid(columns: columns, spacing: 0) {
                        ForEach(Array(albums.enumerated()), id: \.element.id) { index, album in
                            NavigationLink(value: CrateDestination.album(
                                album,
                                gridContext: gridContext.map { GridContext(albums: $0, tappedIndex: index) }
                            )) {
                                AnimatedGridItemView(album: album, index: index)
                            }
                            .buttonStyle(.plain)
                            .onAppear {
                                if album == albums.last {
                                    onLoadMore()
                                }
                            }
                        }
                    }

                    if isLoadingMore {
                        ProgressView()
                            .tint(.brandPink)
                            .padding()
                    }
                }
            }
            .background(.black)
            .onChange(of: scrollToTopTrigger) {
                withAnimation(nil) {
                    proxy.scrollTo("grid-top", anchor: .top)
                }
            }
        }
    }
}

// MARK: - macOS Detail Transition

/// On macOS, NavigationStack uses a crossfade that is invisible between two dark views.
/// This modifier adds a visible slide-and-fade appear animation on macOS only.
/// On iOS, it's a complete no-op — the native slide transition handles everything.
extension View {
    @ViewBuilder
    func macOSDetailTransition() -> some View {
        #if os(macOS)
        modifier(MacOSDetailAppearModifier())
        #else
        self
        #endif
    }
}

#if os(macOS)
private struct MacOSDetailAppearModifier: ViewModifier {
    @State private var isPresented = false
    @State private var isDismissing = false
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            let offScreenX = max(geometry.size.width, 800)

            ZStack {
                Color.black

                ProgressView()
                    .tint(.brandPink)
                    .opacity(isPresented ? 0 : 1)

                content
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .offset(x: isPresented ? 0 : offScreenX)
                    .opacity(isPresented ? 1 : 0)
            }
        }
        .background { Color.black.ignoresSafeArea() }
        .overlay(alignment: .topLeading) {
            Button {
                guard !isDismissing else { return }
                isDismissing = true
                withAnimation(.spring(duration: 0.35, bounce: 0.0)) {
                    isPresented = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial.opacity(0.6), in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut("[", modifiers: .command)
            .padding(.top, 12)
            .padding(.leading, 12)
            .opacity(isPresented ? 1 : 0)
        }
        .task {
            // Wait for content to load (artwork, tracks, layout) before sliding in.
            // View is invisible (opacity 0) during this wait so nothing flashes.
            try? await Task.sleep(for: .milliseconds(500))
            withAnimation(.spring(duration: 0.4, bounce: 0.0)) {
                isPresented = true
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(.hidden, for: .windowToolbar)
    }
}
#endif

#Preview {
    NavigationStack {
        AlbumGridView(
            albums: [],
            isLoadingMore: false,
            onLoadMore: {}
        )
    }
}
