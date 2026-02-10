import SwiftUI
import SwiftData

/// Settings screen with the Crate Dial slider and feed diagnostics.
/// Presented as a sheet on iOS or via Cmd+, on macOS.
struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var dialStore = CrateDialStore()
    @State private var sliderValue: Double = 3
    @State private var showDiagnostics: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Crate Dial")
                            .font(.headline)

                        HStack {
                            Text("My Crate")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Mystery")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: $sliderValue,
                            in: 1...5,
                            step: 1
                        ) {
                            Text("Crate Dial")
                        }
                        .onChange(of: sliderValue) { _, newValue in
                            if let position = CrateDialPosition(rawValue: Int(newValue)) {
                                dialStore.position = position
                            }
                        }

                        // Current position label
                        if let position = CrateDialPosition(rawValue: Int(sliderValue)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(position.label)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Text(position.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } footer: {
                    Text("Changes take effect on next launch.")
                }

                // MARK: - Feed Diagnostics

                Section {
                    Button(showDiagnostics ? "Hide Diagnostics" : "Show Feed Diagnostics") {
                        showDiagnostics.toggle()
                    }
                } footer: {
                    Text("Debug info for validating the feedback loop.")
                }

                if showDiagnostics {
                    FeedDiagnosticsView(modelContext: modelContext, dialPosition: dialStore.position)
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            #endif
        }
        .onAppear {
            sliderValue = Double(dialStore.position.rawValue)
        }
    }
}

#Preview {
    SettingsView()
}
