import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var benefits: [String] = [
        "Unlimited blocks",
        "Unlimited runs",
        "Priority processing"
    ]

    private let subscriptionManager: SubscriptionManaging

    init(subscriptionManager: SubscriptionManaging) {
        self.subscriptionManager = subscriptionManager
    }

    func upgrade() {
        subscriptionManager.toggleProForDebug()
    }
}
