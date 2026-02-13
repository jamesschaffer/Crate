import SwiftUI

/// Debug view showing the state of the auto-advance album queue.
/// Follows the same pattern as FeedDiagnosticsView.
struct QueueDiagnosticsView: View {

    let diagnostics: AlbumQueueDiagnostics

    var body: some View {
        Group {
            Section("Queue Status") {
                statusRow(
                    label: "Auto-advance",
                    value: diagnostics.isActive ? "Active" : "Inactive",
                    pass: true
                )
                statusRow(
                    label: "Grid albums",
                    value: "\(diagnostics.gridAlbumCount)",
                    pass: diagnostics.gridAlbumCount > 0 || !diagnostics.isActive
                )
                statusRow(
                    label: "Track position",
                    value: diagnostics.trackCount > 0
                        ? "\(diagnostics.trackPosition + 1) of \(diagnostics.trackCount)"
                        : "—",
                    pass: true
                )
                statusRow(
                    label: "Pre-fetch needed",
                    value: diagnostics.shouldPrefetch ? "Yes" : "No",
                    pass: true
                )
                statusRow(
                    label: "Next batch ready",
                    value: diagnostics.nextBatchReady ? "Yes" : "No",
                    pass: !diagnostics.shouldPrefetch || diagnostics.nextBatchReady
                )
                statusRow(
                    label: "Batch exhausted",
                    value: diagnostics.batchExhausted ? "Yes" : "No",
                    pass: true
                )
            }

            if !diagnostics.currentBatchAlbums.isEmpty {
                Section("Current Batch (\(diagnostics.currentBatchAlbums.count))") {
                    ForEach(Array(diagnostics.currentBatchAlbums.enumerated()), id: \.offset) { _, title in
                        HStack(spacing: 8) {
                            if title == diagnostics.currentAlbumTitle {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(.brandPink)
                                    .font(.caption)
                            }
                            Text(title)
                                .font(.body)
                                .fontWeight(title == diagnostics.currentAlbumTitle ? .semibold : .regular)
                        }
                    }
                }
            }

            if !diagnostics.trackQueue.isEmpty {
                Section("Track Queue (\(diagnostics.trackQueue.count))") {
                    ForEach(diagnostics.trackQueue) { entry in
                        HStack(spacing: 8) {
                            if entry.isCurrent {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundStyle(.brandPink)
                                    .font(.caption2)
                                    .frame(width: 16)
                            } else {
                                Text("\(entry.id + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .frame(width: 16)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.trackTitle)
                                    .font(.subheadline)
                                    .fontWeight(entry.isCurrent ? .semibold : .regular)
                                Text(entry.albumTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .opacity(entry.id < diagnostics.trackPosition ? 0.4 : 1)
                    }
                }
            }
        }
    }

    private func statusRow(label: String, value: String, pass: Bool) -> some View {
        HStack {
            Image(systemName: pass ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(pass ? .green : .red)
                .font(.subheadline)
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
