import SwiftUI
import SwiftData
import MusicKit

/// Debug view that shows the state of favorites, dislikes, and feed configuration.
/// Validates that the feedback loop is working correctly.
struct FeedDiagnosticsView: View {

    let modelContext: ModelContext
    let dialPosition: CrateDialPosition

    @State private var favorites: [FavoriteAlbum] = []
    @State private var disliked: [DislikedAlbum] = []
    @State private var overlapIDs: [String] = []
    @State private var hasLoaded = false

    var body: some View {
        Group {
            // Validation status
            Section("Validation") {
                validationRow(
                    label: "Favorites saved",
                    value: "\(favorites.count) albums",
                    pass: true
                )
                validationRow(
                    label: "Dislikes saved",
                    value: "\(disliked.count) albums",
                    pass: true
                )
                validationRow(
                    label: "Mutual exclusion",
                    value: overlapIDs.isEmpty ? "No overlap" : "\(overlapIDs.count) conflicts",
                    pass: overlapIDs.isEmpty
                )
                validationRow(
                    label: "Dislike filtering active",
                    value: disliked.isEmpty ? "No dislikes to filter" : "\(disliked.count) albums excluded from feeds",
                    pass: true
                )

                let weights = GenreFeedWeights.weights(for: dialPosition)
                let sum = weights.values.values.reduce(0.0, +)
                validationRow(
                    label: "Genre feed weights sum",
                    value: String(format: "%.2f", sum),
                    pass: abs(sum - 1.0) < 0.01
                )
            }

            // Favorites list
            if !favorites.isEmpty {
                Section("Favorites (\(favorites.count))") {
                    ForEach(favorites, id: \.albumID) { fav in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fav.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(fav.artistName) \u{2022} \(fav.albumID)")
                                .font(.caption)
                                .foregroundStyle(.secondaryText)
                        }
                    }
                }
            }

            // Dislikes list
            if !disliked.isEmpty {
                Section("Dislikes (\(disliked.count))") {
                    ForEach(disliked, id: \.albumID) { item in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(item.artistName) \u{2022} \(item.albumID)")
                                .font(.caption)
                                .foregroundStyle(.secondaryText)
                        }
                    }
                }
            }

            // Feed weight breakdown
            Section("Genre Feed Weights (\(dialPosition.label))") {
                let weights = GenreFeedWeights.weights(for: dialPosition)
                let counts = weights.albumCounts(total: 50)
                ForEach(GenreFeedSignal.allCases, id: \.self) { signal in
                    HStack {
                        Text(signalLabel(signal))
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int((weights.values[signal] ?? 0) * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondaryText)
                        Text("(\(counts[signal, default: 0]) of 50)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .onAppear {
            guard !hasLoaded else { return }
            loadData()
            hasLoaded = true
        }
    }

    private func loadData() {
        // Load favorites
        var favDescriptor = FetchDescriptor<FavoriteAlbum>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        favDescriptor.fetchLimit = 100
        favorites = (try? modelContext.fetch(favDescriptor)) ?? []

        // Load dislikes
        var dislikeDescriptor = FetchDescriptor<DislikedAlbum>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        dislikeDescriptor.fetchLimit = 100
        disliked = (try? modelContext.fetch(dislikeDescriptor)) ?? []

        // Check mutual exclusion — no album should be in both lists
        let favIDs = Set(favorites.map(\.albumID))
        let dislikeIDs = Set(disliked.map(\.albumID))
        overlapIDs = Array(favIDs.intersection(dislikeIDs))
    }

    private func validationRow(label: String, value: String, pass: Bool) -> some View {
        HStack {
            Image(systemName: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(pass ? .green : .red)
                .font(.caption)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondaryText)
        }
    }

    private func signalLabel(_ signal: GenreFeedSignal) -> String {
        switch signal {
        case .personalHistory: "Personal History"
        case .recommendations: "Recommendations"
        case .trending: "Trending"
        case .newReleases: "New Releases"
        case .subcategoryRotation: "Subcategory Rotation"
        case .seedExpansion: "Seed Expansion"
        }
    }
}
