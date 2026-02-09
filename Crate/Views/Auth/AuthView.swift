import SwiftUI

/// Displayed when the user has not yet authorized MusicKit access.
///
/// Shows a welcome message and a button to trigger the system
/// authorization prompt. Also handles the "denied" state with
/// instructions to enable in Settings.
struct AuthView: View {

    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App icon / branding area
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Crate")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Browse albums by genre.\nListen to full albums, front to back.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Authorization state
            switch authViewModel.authorizationStatus {
            case .notDetermined:
                Button {
                    Task {
                        await authViewModel.requestAuthorization()
                    }
                } label: {
                    Label("Connect Apple Music", systemImage: "music.note")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)

            case .denied, .restricted:
                VStack(spacing: 12) {
                    Text("Apple Music access is required")
                        .font(.headline)

                    Text("Open Settings and enable Music access for Crate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    #if os(iOS)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(.bordered)
                    #else
                    Text("System Preferences > Security & Privacy > Privacy > Media & Apple Music")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    #endif
                }
                .padding(.horizontal, 32)

            case .authorized:
                // This state means we're about to transition to ContentView.
                ProgressView("Loading...")

            @unknown default:
                Text("Unexpected authorization state")
                    .foregroundStyle(.secondary)
            }

            if authViewModel.isLoading {
                ProgressView()
                    .padding()
            }

            if let error = authViewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
    }
}

#Preview {
    AuthView()
        .environment(AuthViewModel())
}
