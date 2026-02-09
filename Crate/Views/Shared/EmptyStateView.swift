import SwiftUI

/// A centered message for empty or error states.
/// Shows a title and explanatory message.
struct EmptyStateView: View {

    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        title: "No albums found",
        message: "Try selecting a different genre or subcategory."
    )
}
