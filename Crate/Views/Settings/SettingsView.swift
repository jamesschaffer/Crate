import SwiftUI
import SwiftData

/// Settings screen with the Crate Algorithm radio selector and feed diagnostics.
/// Presented as a sheet on iOS or via Cmd+, on macOS.
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext

    var onDialChanged: (() -> Void)?

    @State private var dialStore = CrateDialStore()
    @State private var selectedPosition: CrateDialPosition = .mixedCrate
    @State private var showDiagnostics: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Crate Algorithm Settings")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .listRowSeparator(.hidden)

                    Text("My Personal Taste")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)

                    ForEach(CrateDialPosition.allCases, id: \.rawValue) { position in
                        Button {
                            selectedPosition = position
                            dialStore.position = position
                            onDialChanged?()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedPosition == position ? "circle.fill" : "circle")
                                    .foregroundStyle(selectedPosition == position ? Color.brandPink : .secondary)
                                    .imageScale(.small)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(position.label)
                                        .font(.headline)

                                    Text(position.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Mystery Selections")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowSeparator(.hidden)
                }

                // MARK: - Algorithm Diagnostics

                Section {
                    Button(showDiagnostics ? "Hide Algorithm Settings" : "Show Algorithm Settings") {
                        showDiagnostics.toggle()
                    }
                } footer: {
                    Text("Debug info for validating the feedback loop.")
                }

                if showDiagnostics {
                    FeedDiagnosticsView(modelContext: modelContext, dialPosition: selectedPosition)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .onAppear {
            selectedPosition = dialStore.position
        }
    }
}

#Preview {
    SettingsView()
}
