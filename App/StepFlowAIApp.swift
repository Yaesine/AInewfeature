import SwiftUI

@main
struct StepFlowAIApp: App {
    @AppStorage("stepflow.didOnboard") private var didOnboard = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didOnboard {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
            .tint(DesignSystem.Colors.brandOrange)
        }
    }
}
