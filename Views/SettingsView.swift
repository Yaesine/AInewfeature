import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    let onShowPaywall: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("API Provider") {
                    Text("OpenAI")
                }

                Section("API Key") {
                    SecureField("sk-...", text: $viewModel.apiKeyInput)
                    Button("Test Key") {
                        Task {
                            await viewModel.testAPIKey()
                        }
                    }
                    .disabled(viewModel.isTestingKey)

                    if let message = viewModel.testStatusMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Model") {
                    TextField("Model name", text: $viewModel.settings.modelName)
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", viewModel.settings.temperature))
                    }
                    Slider(value: $viewModel.settings.temperature, in: 0...1, step: 0.1)
                }

                Section("Limits") {
                    Text("Free: up to 3 blocks, 10 runs/day")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("Manage Subscription") {
                        onShowPaywall()
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                }
            }
        }
    }
}
