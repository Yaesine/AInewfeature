import SwiftUI

struct OnboardingView: View {
    @AppStorage("stepflow.didOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            DesignSystem.gradientBackground
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text("StepFlow AI")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        Text("Design workflows that transform text in a single run.")
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    CardView {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeaderView(
                                title: "How it works",
                                subtitle: "Create steps, paste text, run to transform."
                            )
                            VStack(alignment: .leading, spacing: 12) {
                                Text("1. Add AI or Formatter steps.")
                                Text("2. Paste or type your input.")
                                Text("3. Run once to get a final result.")
                            }
                            .font(.body)
                        }
                    }

                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(
                                title: "Use your own API key",
                                subtitle: "Add it in Settings anytime to enable AI steps."
                            )
                            Text("You can start with formatter steps while you set up your key.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button("Continue") {
                        didOnboard = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: DesignSystem.maxContentWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
