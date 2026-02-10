import SwiftUI
import SwiftData

/// Settings screen with the Crate Dial slider and feed diagnostics.
/// Presented as a sheet on iOS or via Cmd+, on macOS.
struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext

    var onDialChanged: (() -> Void)?

    @State private var dialStore = CrateDialStore()
    @State private var sliderValue: Double = 3
    @State private var showDiagnostics: Bool = false
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Crate Dial")
                            .font(.title3)
                            .fontWeight(.semibold)

                        HStack {
                            Text("My Crate")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("Mystery")
                                .font(.subheadline)
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
                            debounceTask?.cancel()
                            debounceTask = Task {
                                try? await Task.sleep(for: .seconds(1))
                                guard !Task.isCancelled else { return }
                                onDialChanged?()
                            }
                        }

                        // Current position label — fixed height to prevent layout jumping
                        VStack(alignment: .leading, spacing: 4) {
                            if let position = CrateDialPosition(rawValue: Int(sliderValue)) {
                                Text(position.label)
                                    .font(.body)
                                    .fontWeight(.semibold)

                                Text(position.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(height: 50, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 8)
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
