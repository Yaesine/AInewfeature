import SwiftUI
import UIKit

// MARK: - Root tabs (P0)

struct RootTabView: View {
    @StateObject private var workflowsViewModel = WorkflowsViewModel()
    @StateObject private var templatesViewModel = TemplatesViewModel()

    @State private var selectedTab: Tab = .workflows

    enum Tab: Hashable {
        case workflows
        case templates
        case history
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkflowScreen(viewModel: workflowsViewModel)
                .tabItem { Label("Workflows", systemImage: "flowchart") }
                .tag(Tab.workflows)

            TemplatesView(templatesViewModel: templatesViewModel, workflowsViewModel: workflowsViewModel)
                .tabItem { Label("Templates", systemImage: "sparkles.rectangle.stack") }
                .tag(Tab.templates)

            HistoryView(historyStore: workflowsViewModel.historyStore, isPro: workflowsViewModel.subscriptionManager.isPro)
                .tabItem { Label("History", systemImage: "clock") }
                .tag(Tab.history)

            SettingsView(
                viewModel: workflowsViewModel.settingsViewModel,
                subscriptionManager: workflowsViewModel.subscriptionManager,
                onShowPaywall: {
                    workflowsViewModel.showPaywall = true
                    workflowsViewModel.paywallReason = "Upgrade to Pro to unlock more features."
                },
                showsDoneButton: false
            )
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(Tab.settings)
        }
    }
}

// MARK: - Workflows editor

struct WorkflowScreen: View {
    @ObservedObject var viewModel: WorkflowsViewModel

    @State private var showAddStep = false
    @State private var editingBlock: Block?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        header

                        QuickActionsRow(viewModel: viewModel)

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(
                                    title: "Workflow",
                                    subtitle: "Name and organize your steps."
                                )
                                TextField("My Workflow", text: Binding(
                                    get: { viewModel.workflow.name },
                                    set: { viewModel.updateWorkflowName($0) }
                                ))
                                .dsFieldStyle()
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
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
                                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous)
                                        .fill(DesignSystem.Colors.controlFill)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Metrics.controlCornerRadius, style: .continuous)
                                        .stroke(DesignSystem.Colors.cardStroke, lineWidth: DesignSystem.Metrics.hairline)
                                )
                                HStack {
                                    Text("\(viewModel.workflow.inputText.count) characters")
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    Spacer()
                                    Button {
                                        if let pasted = UIPasteboard.general.string {
                                            viewModel.updateInputText(pasted)
                                        }
                                    } label: {
                                        Label("Paste", systemImage: "doc.on.clipboard")
                                    }
                                    .buttonStyle(.bordered)
                                    Button(role: .destructive) {
                                        viewModel.updateInputText("")
                                    } label: {
                                        Label("Clear", systemImage: "xmark.circle")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            SectionHeaderView(
                                title: "Steps",
                                subtitle: "Drag to reorder. Tap edit to refine each step."
                            )
                            if viewModel.workflow.blocks.isEmpty {
                                CardView {
                                    Text("Add your first step to begin.")
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                            } else {
                                VStack(spacing: DesignSystem.Spacing.m) {
                                    ForEach(viewModel.workflow.blocks) { block in
                                        BlockCardView(
                                            block: block,
                                            onEdit: { editingBlock = block },
                                            onMoveUp: { viewModel.moveBlock(id: block.id, direction: -1) },
                                            onMoveDown: { viewModel.moveBlock(id: block.id, direction: 1) },
                                            onDelete: { viewModel.deleteBlock(id: block.id) }
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    .padding(.bottom, 24)
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .navigationTitle("Workflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showWorkflows = true
                    } label: {
                        Label("My Workflows", systemImage: "square.stack.3d.up")
                            .labelStyle(.iconOnly)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView(
                    viewModel: viewModel.settingsViewModel,
                    subscriptionManager: viewModel.subscriptionManager
                ) {
                    viewModel.showPaywall = true
                    viewModel.paywallReason = "Upgrade to Pro to unlock more features."
                }
            }
            .sheet(isPresented: $viewModel.showOutput) {
                OutputView(output: viewModel.outputText, trace: viewModel.outputTrace)
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                PaywallView(
                    viewModel: PaywallViewModel(subscriptionManager: viewModel.subscriptionManager),
                    contextMessage: viewModel.paywallReason
                )
            }
            .sheet(isPresented: $viewModel.showWorkflows) {
                MyWorkflowsView(viewModel: viewModel)
            }
        }
    }

    private var limitMessage: String {
        if viewModel.subscriptionManager.isPro {
            return "Pro: unlimited blocks and runs."
        }
        return "Free: up to 3 blocks, 10 runs/day."
    }

    private var header: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.m) {
            IconBadge(systemName: "flowchart.fill", color: .accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("Build a workflow")
                    .font(.title3.weight(.semibold))
                Text("Chain AI + formatter steps to transform your text in one run.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal)
    }

    private var bottomBar: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            Text(limitMessage)
                .font(.footnote)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            HStack(spacing: DesignSystem.Spacing.m) {
                Button {
                    showAddStep = true
                } label: {
                    Label("Add step", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    viewModel.runWorkflow()
                } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(viewModel.workflow.inputText.trimmed.isEmpty || viewModel.workflow.blocks.isEmpty)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .frame(maxWidth: DesignSystem.maxContentWidth)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Actions (P0)

struct QuickActionsRow: View {
    @ObservedObject var viewModel: WorkflowsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                Spacer()
                if !viewModel.subscriptionManager.isPro {
                    Text(viewModel.canUseQuickActions() ? "Free" : "Locked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(viewModel.canUseQuickActions() ? DesignSystem.Colors.secondaryText : Color.accentColor)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(WorkflowsViewModel.QuickAction.allCases) { action in
                        Button {
                            viewModel.runQuickAction(action)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: action.systemImage)
                                Text(action.title)
                                    .font(.subheadline.weight(.semibold))
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(.thinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(DesignSystem.Colors.cardStroke, lineWidth: DesignSystem.Metrics.hairline)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - My Workflows (P0)

struct MyWorkflowsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkflowsViewModel

    @State private var renamingID: UUID?
    @State private var renameText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground.ignoresSafeArea()
                List {
                    Section {
                        Button {
                            viewModel.createNewWorkflow()
                        } label: {
                            Label("New Workflow", systemImage: "plus")
                        }
                    }

                    Section("My Workflows") {
                        ForEach(viewModel.workflows) { item in
                            Button {
                                viewModel.selectWorkflow(item.id)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: item.id == viewModel.store.selectedWorkflowID ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.id == viewModel.store.selectedWorkflowID ? Color.accentColor : DesignSystem.Colors.secondaryText)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.workflow.name)
                                            .font(.headline)
                                        Text("\(item.workflow.blocks.count) steps")
                                            .font(.caption)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                    Spacer()
                                }
                            }
                            .contextMenu {
                                Button("Rename") {
                                    renamingID = item.id
                                    renameText = item.workflow.name
                                }
                                Button("Duplicate") {
                                    viewModel.duplicateWorkflow(item.id)
                                }
                                Button("Delete", role: .destructive) {
                                    viewModel.deleteWorkflow(item.id)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("My Workflows")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Rename workflow", isPresented: Binding(
                get: { renamingID != nil },
                set: { if !$0 { renamingID = nil } }
            )) {
                TextField("Name", text: $renameText)
                Button("Save") {
                    if let id = renamingID {
                        viewModel.renameWorkflow(id, to: renameText.trimmed.isEmpty ? "Untitled" : renameText)
                    }
                    renamingID = nil
                }
                Button("Cancel", role: .cancel) { renamingID = nil }
            }
        }
    }
}

// MARK: - Templates (P0)

struct TemplatesView: View {
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workflowsViewModel: WorkflowsViewModel

    @State private var selectedTemplate: WorkflowTemplate?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                        header

                        ForEach(TemplateCategory.allCases) { category in
                            if let templates = templatesViewModel.templatesByCategory[category] {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                    Text(category.rawValue)
                                        .font(.headline)
                                        .padding(.horizontal)

                                    VStack(spacing: 12) {
                                        ForEach(templates) { template in
                                            Button {
                                                selectedTemplate = template
                                            } label: {
                                                TemplateRow(template: template, isLocked: templatesViewModel.isLocked(template, isPro: workflowsViewModel.subscriptionManager.isPro))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 24)
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template, templatesViewModel: templatesViewModel, workflowsViewModel: workflowsViewModel)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.m) {
            IconBadge(systemName: "sparkles.rectangle.stack", color: .accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text("One‑tap templates")
                    .font(.title3.weight(.semibold))
                Text("Start fast with proven workflows.")
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}

struct TemplateRow: View {
    let template: WorkflowTemplate
    let isLocked: Bool

    var body: some View {
        CardView {
            HStack(alignment: .top, spacing: 12) {
                IconBadge(systemName: "wand.and.stars", color: .accentColor)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(template.name)
                            .font(.headline)
                        Spacer()
                        if isLocked {
                            Text("PRO")
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.16))
                                .clipShape(Capsule())
                        }
                    }
                    Text(template.description)
                        .font(.subheadline)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                    Text("\(template.blocks.count) steps")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }
            }
        }
    }
}

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let template: WorkflowTemplate
    @ObservedObject var templatesViewModel: TemplatesViewModel
    @ObservedObject var workflowsViewModel: WorkflowsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.l) {
                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(title: template.name, subtitle: template.description)
                                Text(template.category.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                        }

                        CardView {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                SectionHeaderView(title: "Steps", subtitle: nil)
                                ForEach(Array(template.blocks.enumerated()), id: \.offset) { idx, block in
                                    HStack(spacing: 10) {
                                        IconBadge(systemName: block.type == .ai ? "sparkles" : "wand.and.stars")
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(block.type.displayName)
                                                .font(.headline)
                                            Text(block.displayDetail)
                                                .font(.subheadline)
                                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }

                        VStack(spacing: DesignSystem.Spacing.m) {
                            Button {
                                applyToCurrent()
                                dismiss()
                            } label: {
                                Label("Use Template", systemImage: "arrow.down.doc")
                            }
                            .buttonStyle(PrimaryButtonStyle())

                            Button {
                                saveAsNew()
                                dismiss()
                            } label: {
                                Label("Save as New Workflow", systemImage: "square.stack.3d.up")
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .padding()
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func gateIfNeeded() -> Bool {
        if templatesViewModel.isLocked(template, isPro: workflowsViewModel.subscriptionManager.isPro) {
            workflowsViewModel.showPaywall = true
            workflowsViewModel.paywallReason = "Templates are a Pro feature. Upgrade to unlock unlimited templates."
            return true
        }
        return false
    }

    private func applyToCurrent() {
        guard !gateIfNeeded() else { return }
        var w = workflowsViewModel.workflow
        w.name = template.name
        w.blocks = template.blocks.map { Block(type: $0.type, instruction: $0.instruction, formatterOperation: $0.formatterOperation) }
        workflowsViewModel.workflow = w
    }

    private func saveAsNew() {
        guard !gateIfNeeded() else { return }
        if !workflowsViewModel.subscriptionManager.isPro, workflowsViewModel.store.workflows.count >= 1 {
            workflowsViewModel.showPaywall = true
            workflowsViewModel.paywallReason = "Free plan allows 1 saved workflow. Upgrade to Pro to save more."
            return
        }
        let created = workflowsViewModel.store.createNewWorkflow(named: template.name)
        var w = created.workflow
        w.blocks = template.blocks.map { Block(type: $0.type, instruction: $0.instruction, formatterOperation: $0.formatterOperation) }
        workflowsViewModel.store.selectedWorkflow = w
    }
}

// MARK: - History (P0)

struct HistoryView: View {
    @ObservedObject var historyStore: HistoryStore
    let isPro: Bool

    @State private var selected: HistoryItem?

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground.ignoresSafeArea()
                if historyStore.items.isEmpty {
                    VStack(spacing: 10) {
                        IconBadge(systemName: "clock", color: .accentColor)
                        Text("No history yet")
                            .font(.headline)
                        Text("Run a workflow or a quick action to save results here.")
                            .font(.subheadline)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        Section {
                            ForEach(historyStore.items) { item in
                                Button {
                                    selected = item
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(item.workflowName)
                                                .font(.headline)
                                            Spacer()
                                            Text(item.date, style: .time)
                                                .font(.caption)
                                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                                        }
                                        if !item.inputSnippet.isEmpty {
                                            Text(item.inputSnippet)
                                                .font(.caption)
                                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                            .onDelete { offsets in
                                for idx in offsets {
                                    let id = historyStore.items[idx].id
                                    historyStore.delete(id)
                                }
                            }
                        } footer: {
                            if !isPro {
                                Text("Free keeps the last 5 results. Pro keeps the last 50.")
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selected) { item in
                OutputView(output: item.output, trace: item.trace)
            }
        }
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
