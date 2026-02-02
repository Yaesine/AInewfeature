import Foundation

@MainActor
final class PaywallViewModel: ObservableObject {
    @Published var benefits: [String] = [
        "One‑tap professional writing",
        "Unlimited templates",
        "Unlimited saved workflows",
        "History: save up to 50 results",
        "Unlimited quick actions",
        "Unlimited blocks & runs"
    ]

    @Published var statusMessage: String?

    private let subscriptionManager: SubscriptionManaging

    init(subscriptionManager: SubscriptionManaging) {
        self.subscriptionManager = subscriptionManager
    }

    func upgrade() {
        subscriptionManager.toggleProForDebug()
    }

    func tryPro() {
        upgrade()
    }

    func restorePurchases() {
        // P0 stub: no StoreKit backend yet.
        statusMessage = "Restore Purchases is coming soon."
    }
}
