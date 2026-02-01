import SwiftUI

struct OnboardingView: View {
    @AppStorage("stepflow.didOnboard") private var didOnboard = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("StepFlow AI")
                .font(.largeTitle)
                .fontWeight(.semibold)
            Text("Create steps, paste text, run to transform.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Text("Add your OpenAI API key in Settings to unlock AI steps. You can continue without it.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Button("Continue") {
                didOnboard = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom, 40)
        }
        .padding()
    }
}
