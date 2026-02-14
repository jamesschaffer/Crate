import SwiftUI

/// Displays an AI-generated album review or a generate button.
struct AlbumReviewView: View {

    let album: CrateAlbum

    @State private var viewModel = AlbumReviewViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            if viewModel.isGenerating {
                LoadingView(message: "Generating review...")
            } else if let review = viewModel.review {
                reviewContent(review)
            } else if let error = viewModel.errorMessage {
                errorState(error)
            } else {
                emptyState
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            viewModel.loadCachedReview(albumID: album.id.rawValue)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "text.document")
                .font(.system(size: 40))
                .foregroundStyle(.secondaryText)

            Text("No review yet")
                .font(.headline)

            Text("Generate an AI-powered review based on critical reception, cultural impact, and musical merit.")
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.generateReview(for: album) }
            } label: {
                Text("Generate Review")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPink)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Review Content

    private func reviewContent(_ review: AlbumReview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rating + recommendation badge
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(String(format: "%.1f", review.rating))
                    .font(.system(size: 36, weight: .bold, design: .rounded))

                Text("/ 10")
                    .font(.title3)
                    .foregroundStyle(.secondaryText)

                Spacer()

                Text(review.recommendation)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.brandPink.opacity(0.15))
                    .foregroundStyle(.brandPink)
                    .clipShape(Capsule())
            }

            // Summary
            Text(review.contextSummary)
                .font(.body)

            // Bullets
            VStack(alignment: .leading, spacing: 8) {
                ForEach(review.contextBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(.brandPink)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        Text(bullet)
                            .font(.subheadline)
                    }
                }
            }

            // Timestamp + regenerate
            HStack {
                Text("Generated \(review.dateGenerated.formatted(.relative(presentation: .named)))")
                    .font(.caption)
                    .foregroundStyle(.secondaryText)

                Spacer()

                if viewModel.isRegenerating {
                    ProgressView()
                        .controlSize(.small)
                        .tint(.brandPink)
                } else {
                    Button {
                        Task { await viewModel.generateReview(for: album) }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(.brandPink)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Error State

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondaryText)

            Text("Review Failed")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.generateReview(for: album) }
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.brandPink)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
