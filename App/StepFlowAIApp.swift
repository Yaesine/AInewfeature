import SwiftUI

@main
struct StepFlowAIApp: App {
    @AppStorage("stepflow.didOnboard") private var didOnboard = false

    var body: some Scene {
        WindowGroup {
            if didOnboard {
                WorkflowScreen(viewModel: WorkflowViewModel())
            } else {
                OnboardingView()
            }
        }
    }
}
