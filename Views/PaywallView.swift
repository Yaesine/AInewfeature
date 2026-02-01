import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaywallViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("StepFlow AI Pro")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.benefits, id: \.self) { benefit in
                        Text("• \(benefit)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                Button("Upgrade to Pro") {
                    viewModel.upgrade()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
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
