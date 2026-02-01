import Foundation

protocol AnalyticsService {
    func track(event: String, properties: [String: String])
}

struct NoOpAnalyticsService: AnalyticsService {
    func track(event: String, properties: [String : String]) {}
}
