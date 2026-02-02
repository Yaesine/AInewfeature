import SwiftUI

struct OnboardingView: View {
    @AppStorage("stepflow.didOnboard") private var didOnboard = false
    @State private var step: Step = .welcome
    @State private var showAPIKeySetup = false

    @StateObject private var settingsViewModel = SettingsViewModel(
        persistence: UserDefaultsPersistenceService()
    )

    private enum Step: Int, CaseIterable {
        case welcome
        case build
        case apiKey
        case ready

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .build: return "Build workflows"
            case .apiKey: return "Connect your key"
            case .ready: return "Ready"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.gradientBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    TabView(selection: $step) {
                        welcomePage.tag(Step.welcome)
                        buildPage.tag(Step.build)
                        apiKeyPage.tag(Step.apiKey)
                        readyPage.tag(Step.ready)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .safeAreaInset(edge: .bottom) {
                bottomControls
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        didOnboard = true
                    }
                }
            }
            .sheet(isPresented: $showAPIKeySetup) {
                SettingsView(viewModel: settingsViewModel, subscriptionManager: nil, onShowPaywall: {})
            }
        }
    }

    private var welcomePage: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.xl) {
                VStack(spacing: DesignSystem.Spacing.m) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.14))
                            .frame(width: 88, height: 88)
                        Image(systemName: "flowchart.fill")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    VStack(spacing: 10) {
                        Text("StepFlow AI")
                            .font(.largeTitle.weight(.semibold))
                        Text("Turn messy text into polished output with repeatable workflows.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.top, 18)

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(
                            title: "What you can do",
                            subtitle: "Combine AI and fast local steps."
                        )
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Summarize and rewrite", systemImage: "sparkles")
                            Label("Fix grammar and format", systemImage: "wand.and.stars")
                            Label("Run everything in one tap", systemImage: "play.circle")
                        }
                        .font(.body)
                    }
                }
            }
            .padding()
            .frame(maxWidth: DesignSystem.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 110)
        }
    }

    private var buildPage: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                pageHeader(
                    icon: "square.stack.3d.up.fill",
                    title: "Build workflows",
                    subtitle: "Create steps, reorder them, and reuse them anytime."
                )

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(title: "How it works", subtitle: nil)
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Add AI or Formatter steps", systemImage: "plus.circle")
                            Label("Paste or type your input", systemImage: "doc.plaintext")
                            Label("Tap Run to get a final result", systemImage: "bolt.fill")
                        }
                        .font(.body)
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(
                            title: "Pro tip",
                            subtitle: "Use formatters for instant, offline transformations."
                        )
                        Text("Formatter steps run locally — great for cleanups and structuring before (or after) AI steps.")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding()
            .frame(maxWidth: DesignSystem.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 110)
        }
    }

    private var apiKeyPage: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                pageHeader(
                    icon: "key.fill",
                    title: "Connect your key",
                    subtitle: "Enable AI steps by adding your OpenAI API key."
                )

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(
                            title: "Private by design",
                            subtitle: "Your key is stored in the iOS Keychain on this device."
                        )
                        Text("You can still use formatter-only workflows without adding a key.")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(title: "Set up now (optional)", subtitle: nil)
                        Button {
                            showAPIKeySetup = true
                        } label: {
                            Label("Open API key settings", systemImage: "gearshape")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding()
            .frame(maxWidth: DesignSystem.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 110)
        }
    }

    private var readyPage: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                pageHeader(
                    icon: "checkmark.seal.fill",
                    title: "You’re ready",
                    subtitle: "Create your first workflow and run it on any text."
                )

                CardView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                        SectionHeaderView(title: "Next step", subtitle: nil)
                        Text("Tap “Add step” to start building. You can edit, reorder, and save outputs.")
                            .foregroundStyle(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding()
            .frame(maxWidth: DesignSystem.maxContentWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 110)
        }
    }

    private func pageHeader(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.m) {
            IconBadge(systemName: icon, color: .accentColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var bottomControls: some View {
        VStack(spacing: DesignSystem.Spacing.s) {
            HStack(spacing: 8) {
                ForEach(Step.allCases, id: \.self) { s in
                    Capsule()
                        .fill(s == step ? Color.accentColor : DesignSystem.Colors.cardStroke)
                        .frame(width: s == step ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: step)
                }
            }
            .padding(.top, 2)

            HStack(spacing: DesignSystem.Spacing.m) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        step = Step(rawValue: max(step.rawValue - 1, 0)) ?? .welcome
                    }
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(step == .welcome)

                Button {
                    if step == .ready {
                        didOnboard = true
                        return
                    }
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                        step = Step(rawValue: min(step.rawValue + 1, Step.allCases.count - 1)) ?? .ready
                    }
                } label: {
                    Label(step == .ready ? "Start" : "Next", systemImage: step == .ready ? "sparkles" : "chevron.right")
                }
                .buttonStyle(PrimaryButtonStyle())
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
