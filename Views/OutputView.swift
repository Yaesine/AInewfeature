import SwiftUI
import UIKit

struct OutputView: View {
    @Environment(\.dismiss) private var dismiss
    let output: String
    let trace: [WorkflowTraceStep]

    @State private var showSteps = false

    init(output: String, trace: [WorkflowTraceStep] = []) {
        self.output = output
        self.trace = trace
    }

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
                                .textSelection(.enabled)
                        }
                        .frame(minHeight: 240)
                    }

                    if !trace.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                DisclosureGroup(isExpanded: $showSteps) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(trace) { step in
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("\(step.index). \(step.title)")
                                                    .font(.headline)
                                                Text(step.output)
                                                    .font(.subheadline)
                                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                                                    .lineLimit(showSteps ? nil : 6)
                                                    .textSelection(.enabled)
                                            }
                                            if step.id != trace.last?.id {
                                                Divider().opacity(0.5)
                                            }
                                        }
                                    }
                                    .padding(.top, 6)
                                } label: {
                                    HStack {
                                        Text("Step outputs")
                                            .font(.headline)
                                        Spacer()
                                        Text(showSteps ? "Hide" : "Show")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = output
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        ShareLink(item: output) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Text("Saved to History automatically.")
                        .font(.footnote)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
                .padding()
                .frame(maxWidth: DesignSystem.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("Result")
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
