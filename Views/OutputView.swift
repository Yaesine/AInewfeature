import SwiftUI
import UIKit

struct OutputView: View {
    @Environment(\.dismiss) private var dismiss
    let output: String
    let onSaveNote: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    Text(output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                HStack(spacing: 12) {
                    Button("Copy") {
                        UIPasteboard.general.string = output
                    }
                    .buttonStyle(.bordered)
                    ShareLink(item: output) {
                        Text("Share")
                    }
                    .buttonStyle(.bordered)
                    Button("Save as Note") {
                        onSaveNote()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.bottom, 12)
            }
            .navigationTitle("Result")
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
