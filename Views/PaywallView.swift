import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaywallViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("StepFlow AI Pro")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Unlock higher limits and faster workflows.")
                            .foregroundStyle(.secondary)
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "Pro benefits", subtitle: nil)
                            ForEach(viewModel.benefits, id: \.self) { benefit in
                                Text(benefit)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }

                    Button("Upgrade to Pro") {
                        viewModel.upgrade()
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())

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
