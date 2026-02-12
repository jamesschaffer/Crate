import SwiftUI

/// Welcome screen shown before the user authorizes MusicKit access.
///
/// Displays the AlbumCrate logo and wordmark centered on a black background,
/// with a "Link to Apple Music" button near the bottom. Handles all
/// authorization states: not determined, denied/restricted, and authorized.
struct AuthView: View {

    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + wordmark
                VStack(spacing: 16) {
                    Image("AlbumCrateLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)

                    Image("AlbumCrateWordmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300)
                }

                Spacer()

                // Bottom section: auth button, errors, loading
                bottomContent
                    .padding(.bottom, 60)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Content

    @ViewBuilder
    private var bottomContent: some View {
        switch authViewModel.authorizationStatus {
        case .notDetermined:
            connectButton

        case .denied, .restricted:
            deniedContent

        case .authorized:
            ProgressView()
                .tint(.white)

        @unknown default:
            Text("Unexpected authorization state")
                .foregroundStyle(.secondaryText)
        }

        if authViewModel.isLoading {
            ProgressView()
                .tint(.white)
                .padding(.top, 16)
        }

        if let error = authViewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 8)
        }
    }

    // MARK: - Connect Button

    private var connectButton: some View {
        Button {
            Task {
                await authViewModel.requestAuthorization()
            }
        } label: {
            Label("Link to Apple Music", systemImage: "music.note")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.brandPink)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Denied State

    private var deniedContent: some View {
        VStack(spacing: 12) {
            Text("Apple Music access is required")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Open Settings and enable Music access for AlbumCrate.")
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)

            #if os(iOS)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(Color.brandPink)
            #else
            Text("System Preferences > Security & Privacy > Privacy > Media & Apple Music")
                .font(.caption)
                .foregroundStyle(.secondaryText)
            #endif
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel())
}
