import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    let onShowPaywall: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(
                                    title: "API provider",
                                    subtitle: "Connect your OpenAI key to enable AI steps."
                                )
                                Text("OpenAI")
                                    .font(.headline)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(
                                    title: "API key",
                                    subtitle: "Stored securely in the device Keychain."
                                )
                                SecureField("sk-...", text: $viewModel.apiKeyInput)
                                    .textFieldStyle(.roundedBorder)
                                Button("Test Key") {
                                    Task {
                                        await viewModel.testAPIKey()
                                    }
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .disabled(viewModel.isTestingKey)

                                if let message = viewModel.testStatusMessage {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(
                                    title: "Model",
                                    subtitle: "Default model and temperature."
                                )
                                TextField("Model name", text: $viewModel.settings.modelName)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    Text("Temperature")
                                    Spacer()
                                    Text(String(format: "%.1f", viewModel.settings.temperature))
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $viewModel.settings.temperature, in: 0...1, step: 0.1)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(
                                    title: "Limits",
                                    subtitle: "Upgrade for higher limits."
                                )
                                Text("Free: up to 3 blocks, 10 runs/day")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Button("Manage Subscription") {
                            onShowPaywall()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding()
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
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
