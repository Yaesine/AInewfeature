import SwiftUI
import UIKit

struct OutputView: View {
    @Environment(\.dismiss) private var dismiss
    let output: String
    let onSaveNote: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    CardView {
                        ScrollView {
                            Text(output)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 240)
                    }
                    HStack(spacing: 12) {
                        Button("Copy") {
                            UIPasteboard.general.string = output
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        ShareLink(item: output) {
                            Text("Share")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        Button("Save as Note") {
                            onSaveNote()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
                .frame(maxWidth: DesignSystem.maxContentWidth)
                .frame(maxWidth: .infinity)
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
