import SwiftUI
import UIKit

struct WorkflowScreen: View {
    @StateObject var viewModel: WorkflowViewModel

    @State private var showAddStep = false
    @State private var editingBlock: Block?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        CardView {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeaderView(
                                    title: "Workflow",
                                    subtitle: "Name and organize your steps."
                                )
                                TextField("My Workflow", text: Binding(
                                    get: { viewModel.workflow.name },
                                    set: { viewModel.updateWorkflowName($0) }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(
                                    title: "Input",
                                    subtitle: "Paste the text you want to transform."
                                )
                                TextEditor(text: Binding(
                                    get: { viewModel.workflow.inputText },
                                    set: { viewModel.updateInputText($0) }
                                ))
                                .frame(minHeight: 140)
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                                HStack {
                                    Text("\(viewModel.workflow.inputText.count) characters")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button("Paste") {
                                        if let pasted = UIPasteboard.general.string {
                                            viewModel.updateInputText(pasted)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    Button("Clear") {
                                        viewModel.updateInputText("")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(
                                title: "Steps",
                                subtitle: "Drag to reorder. Tap edit to refine each step."
                            )
                            if viewModel.workflow.blocks.isEmpty {
                                CardView {
                                    Text("Add your first step to begin.")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.workflow.blocks) { block in
                                        BlockCardView(block: block) {
                                            editingBlock = block
                                        }
                                    }
                                    .onMove(perform: viewModel.moveBlock)
                                    .onDelete(perform: viewModel.deleteBlock)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 120)
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
                VStack(spacing: 12) {
                    Text(limitMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 12) {
                        Button("Add Step") {
                            showAddStep = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        Button("Run") {
                            viewModel.runWorkflow()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(viewModel.workflow.inputText.trimmed.isEmpty || viewModel.workflow.blocks.isEmpty)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding()
                .frame(maxWidth: DesignSystem.maxContentWidth)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .navigationTitle("Workflow")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showSettings = true
                    }
                }
            }
            .overlay {
                if viewModel.isRunning {
                    ProgressOverlayView(stepIndex: viewModel.currentStepIndex, totalSteps: viewModel.workflow.blocks.count) {
                        viewModel.cancelRun()
                    }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .sheet(isPresented: $showAddStep) {
                AddStepView { block in
                    viewModel.addBlock(block)
                }
            }
            .sheet(item: $editingBlock) { block in
                AddStepView(existingBlock: block) { updated in
                    viewModel.updateBlock(updated)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel.settingsViewModel) {
                    viewModel.showPaywall = true
                }
            }
            .sheet(isPresented: $viewModel.showOutput) {
                OutputView(output: viewModel.outputText) {
                    viewModel.workflow.history.insert(WorkflowHistoryItem(output: viewModel.outputText), at: 0)
                    viewModel.workflow.history = Array(viewModel.workflow.history.prefix(20))
                    viewModel.saveWorkflow()
                }
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(viewModel: PaywallViewModel(subscriptionManager: viewModel.subscriptionManager))
            }
        }
    }

    private var limitMessage: String {
        if viewModel.subscriptionManager.isPro {
            return "Pro: unlimited blocks and runs."
        }
        return "Free: up to 3 blocks, 10 runs/day."
    }
}

struct ProgressOverlayView: View {
    let stepIndex: Int
    let totalSteps: Int
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                Text("Running step \(min(stepIndex, totalSteps)) of \(totalSteps)")
                    .font(.headline)
                Button("Cancel", action: onCancel)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
            .padding()
        }
    }
}
