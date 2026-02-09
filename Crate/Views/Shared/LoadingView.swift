import SwiftUI

/// Centered loading indicator with an optional message.
struct LoadingView: View {

    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    LoadingView(message: "Loading albums...")
}
