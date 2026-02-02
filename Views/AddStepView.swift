import SwiftUI

struct AddStepView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: BlockType
    @State private var instruction: String
    @State private var formatterKind: FormatterOperation.Kind
    @State private var selectedTone: FormatterTone

    let existingBlock: Block?
    let onSave: (Block) -> Void

    private let instructionExamples = [
        "Summarize",
        "Rewrite professionally",
        "Translate to French",
        "Explain simply",
        "Bullet points"
    ]

    init(existingBlock: Block? = nil, onSave: @escaping (Block) -> Void) {
        self.existingBlock = existingBlock
        self.onSave = onSave
        let initialType = existingBlock?.type ?? .ai
        _selectedType = State(initialValue: initialType)
        _instruction = State(initialValue: existingBlock?.instruction ?? "")
        if let formatter = existingBlock?.formatterOperation {
            _formatterKind = State(initialValue: formatter.kind)
            if case let .tone(tone) = formatter {
                _selectedTone = State(initialValue: tone)
            } else {
                _selectedTone = State(initialValue: .neutral)
            }
        } else {
            _formatterKind = State(initialValue: .fixGrammar)
            _selectedTone = State(initialValue: .neutral)
        }
    }

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
                                    title: "Step type",
                                    subtitle: "Choose an AI step or a deterministic formatter."
                                )
                                Picker("Type", selection: $selectedType) {
                                    Text("AI Step").tag(BlockType.ai)
                                    Text("Formatter").tag(BlockType.formatter)
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        if selectedType == .ai {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                    SectionHeaderView(
                                        title: "Instruction",
                                        subtitle: "Describe the transformation you want."
                                    )
                                    ZStack(alignment: .topLeading) {
                                        if instruction.isEmpty {
                                            Text("e.g. Summarize the input in 5 bullet points")
                                                .foregroundStyle(DesignSystem.Colors.secondaryText)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 14)
                                        }
                                        TextEditor(text: $instruction)
                                            .frame(minHeight: 90)
                                            .padding(8)
                                            .scrollContentBackground(.hidden)
                                    }
                                    .dsFieldStyle()

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: DesignSystem.Spacing.s) {
                                            ForEach(instructionExamples, id: \.self) { example in
                                                Button(example) {
                                                    instruction = example
                                                }
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    HStack {
                                        Text("Up to 200 characters")
                                        Spacer()
                                        Text("\(instruction.count)/200")
                                    }
                                        .font(.caption)
                                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                                }
                            }
                        } else {
                            CardView {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                                    SectionHeaderView(
                                        title: "Formatter",
                                        subtitle: "Deterministic local transformation."
                                    )
                                    Picker("Operation", selection: $formatterKind) {
                                        Text("Fix grammar (AI)").tag(FormatterOperation.Kind.fixGrammar)
                                        Text("Shorten").tag(FormatterOperation.Kind.shorten)
                                        Text("Expand").tag(FormatterOperation.Kind.expand)
                                        Text("Bullet points").tag(FormatterOperation.Kind.bulletPoints)
                                        Text("Tone").tag(FormatterOperation.Kind.tone)
                                    }
                                    if formatterKind == .fixGrammar {
                                        Text("Requires API key. Uses AI for real grammar correction.")
                                            .font(.caption)
                                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                                    }
                                    if formatterKind == .tone {
                                        Picker("Tone", selection: $selectedTone) {
                                            ForEach(FormatterTone.allCases, id: \.self) { tone in
                                                Text(tone.displayName).tag(tone)
                                            }
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: DesignSystem.maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(existingBlock == nil ? "Add Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let block = buildBlock()
                        onSave(block)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isValid: Bool {
        switch selectedType {
        case .ai:
            return !instruction.trimmed.isEmpty
        case .formatter:
            return true
        }
    }

    private func buildBlock() -> Block {
        let blockId = existingBlock?.id ?? UUID()
        switch selectedType {
        case .ai:
            return Block(id: blockId, type: .ai, instruction: instruction.limited(to: 200))
        case .formatter:
            let operation: FormatterOperation
            switch formatterKind {
            case .fixGrammar:
                operation = .fixGrammar
            case .shorten:
                operation = .shorten
            case .expand:
                operation = .expand
            case .bulletPoints:
                operation = .bulletPoints
            case .tone:
                operation = .tone(selectedTone)
            }
            return Block(id: blockId, type: .formatter, formatterOperation: operation)
        }
    }
}
