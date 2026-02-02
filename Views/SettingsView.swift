import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel
    let subscriptionManager: MockSubscriptionManager?
    let onShowPaywall: () -> Void
    var showsDoneButton: Bool = true

    @State private var includedAIEnabled = false
    @State private var showIncludedAIInfo = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(
                                    title: "AI provider",
                                    subtitle: "Use OpenAI (requires billing) or Demo AI to test for free."
                                )

                                Picker("AI provider", selection: $viewModel.settings.aiMode) {
                                    ForEach(SettingsStore.AIMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(
                                    title: "API key",
                                    subtitle: "Stored securely in the device Keychain."
                                )
                                SecureField("sk-...", text: $viewModel.apiKeyInput)
                                    .dsFieldStyle()

                                Button {
                                    Task {
                                        if viewModel.settings.aiMode == .demo {
                                            await viewModel.testDemoAI()
                                        } else {
                                            await viewModel.testAPIKey()
                                        }
                                    }
                                } label: {
                                    Label(
                                        viewModel.isTestingKey ? "Testing..." : (viewModel.settings.aiMode == .demo ? "Test Demo AI" : "Test key"),
                                        systemImage: "checkmark.seal"
                                    )
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .disabled(viewModel.isTestingKey)

                                if viewModel.settings.aiMode == .demo {
                                    Text("Demo AI is for testing only. Outputs are simulated and not as good as real AI.")
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }

                                if let message = viewModel.testStatusMessage {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(
                                    title: "Model",
                                    subtitle: "Default model and temperature."
                                )
                                TextField("Model name", text: $viewModel.settings.modelName)
                                    .dsFieldStyle()
                                HStack {
                                    Text("Temperature")
                                    Spacer()
                                    Text(String(format: "%.1f", viewModel.settings.temperature))
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                                Slider(value: $viewModel.settings.temperature, in: 0...1, step: 0.1)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(
                                    title: "Limits",
                                    subtitle: "Upgrade for higher limits."
                                )
                                Text("Free: up to 3 blocks, 10 runs/day")
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }

                        if subscriptionManager?.isPro == true {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                    SectionHeaderView(
                                        title: "AI mode",
                                        subtitle: "Use Included AI without adding your own key (coming soon)."
                                    )
                                    Toggle(isOn: $includedAIEnabled) {
                                        Text("Use Included AI (Coming soon)")
                                    }
                                    .onChange(of: includedAIEnabled) { _, newValue in
                                        if newValue {
                                            showIncludedAIInfo = true
                                            includedAIEnabled = false
                                        }
                                    }
                                    .tint(Color.accentColor)
                                }
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
            .navigationBarTitleDisplayMode(.inline)
            .alert("Included AI (Coming soon)", isPresented: $showIncludedAIInfo) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This will let Pro users run AI steps without providing an API key. For now, please add your key in Settings.")
            }
            .toolbar {
                if showsDoneButton {
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
}
