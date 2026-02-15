import SwiftUI

/// Displays an AI-generated album review, using the artwork-extracted
/// color for all accent elements (rating, badge, bullets, regenerate).
struct AlbumReviewView: View {

    let album: CrateAlbum
    let recordLabel: String?
    let tintColor: Color

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
                // Shown briefly while .onAppear fires and kicks off generation
                LoadingView(message: "Generating review...")
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
            viewModel.loadCachedReview(albumID: album.id.rawValue)
            if viewModel.review == nil && !viewModel.isGenerating && viewModel.errorMessage == nil {
                Task {
                    await viewModel.generateReview(for: album, recordLabel: recordLabel)
                }
            }
        }
    }

    // MARK: - Review Content

    private func reviewContent(_ review: AlbumReview) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Rating + recommendation badge — vertically centered
            HStack(spacing: 8) {
                Text(String(format: "%.1f", review.rating))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(tintColor)

                Text("/ 10")
                    .font(.title3)
                    .foregroundStyle(.secondaryText)

                Spacer()

                Text(review.recommendation)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tintColor.opacity(0.15))
                    .foregroundStyle(tintColor)
                    .clipShape(Capsule())
            }

            // Summary
            Text(review.contextSummary)
                .font(.body)

            // Bullets — same font as summary, artwork color dots
            VStack(alignment: .leading, spacing: 8) {
                ForEach(review.contextBullets, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(tintColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 7)

                        Text(Self.stripCitations(from: bullet))
                            .font(.body)
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
                        .tint(tintColor)
                } else {
                    Button {
                        Task {
                            await viewModel.generateReview(for: album, recordLabel: recordLabel)
                        }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                            .foregroundStyle(tintColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
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
                Task {
                    await viewModel.generateReview(for: album, recordLabel: recordLabel)
                }
            } label: {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(tintColor)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    /// Strip markdown citation links appended by the Cloud Function.
    /// Format: ` ([Title](url))` → removed.
    private static func stripCitations(from text: String) -> String {
        text.replacingOccurrences(
            of: #"\s*\(\[.*?\]\(.*?\)\)"#,
            with: "",
            options: .regularExpression
        )
    }
}
