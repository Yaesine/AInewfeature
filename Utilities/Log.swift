import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "StepFlowAI"

    static let workflow = Logger(subsystem: subsystem, category: "workflow")
    static let formatter = Logger(subsystem: subsystem, category: "formatter")
    static let ui = Logger(subsystem: subsystem, category: "ui")
}

enum DebugPrint {
    static func line(_ message: String) {
        #if DEBUG
        Swift.print(message)
        #endif
    }
}

