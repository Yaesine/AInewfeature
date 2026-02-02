import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaywallViewModel
    let contextMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                VStack(spacing: DesignSystem.Spacing.l) {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.12))
                                .frame(width: 74, height: 74)
                            Image(systemName: "sparkles")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                        }
                        Text("StepFlow AI Pro")
                            .font(.largeTitle.weight(.semibold))
                        Text("One‑tap writing assistant: save workflows, reuse templates, and keep your results.")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    if let contextMessage, !contextMessage.trimmed.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeaderView(title: "Unlocked with Pro", subtitle: nil)
                                Text(contextMessage)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            SectionHeaderView(title: "Pro benefits", subtitle: nil)
                            ForEach(viewModel.benefits, id: \.self) { benefit in
                                Label(benefit, systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }

                    Button("Try Pro") {
                        viewModel.tryPro()
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button("Restore Purchases") {
                        viewModel.restorePurchases()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if let status = viewModel.statusMessage {
                        Text(status)
                            .font(.footnote)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }

                    Button("Not now") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
                .frame(maxWidth: DesignSystem.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
