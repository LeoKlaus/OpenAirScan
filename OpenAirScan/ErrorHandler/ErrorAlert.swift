//
//  ErrorAlert.swift
//  Paperparrot-Next
//
//  Created by Leo Wehrfritz on 20.12.24.
//

import OSLog

struct ErrorAlert: Identifiable {
    var id = UUID()
    var title: String = "Error"
    var message: String
    var dismissAction: (() -> Void)?
}

class ErrorHandler: ObservableObject {
    
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: ErrorHandler.self)
    )
    
    @Published var currentAlert: ErrorAlert?
    
    @MainActor func handle(_ text: String, while performedTask: String) {
        Self.logger.error("Error while \(performedTask):\n\(text, privacy: .public)")
        currentAlert = ErrorAlert(title: "Error \(performedTask)", message: text)
    }
    
    @MainActor func handle(_ error: Error, while performedTask: String) {
        Self.logger.error("Error while \(performedTask): \(error.localizedDescription, privacy: .public)\n\(String(describing: error), privacy: .public)")
        currentAlert = ErrorAlert(title: "Error \(performedTask)", message: error.localizedDescription)
    }
    
    @MainActor func handle(_ error: Error, while performedTask: String, dismissAction: (() -> Void)?) {
        Self.logger.error("Error while \(performedTask): \(error.localizedDescription, privacy: .public)\n\(String(describing: error), privacy: .public)")
        currentAlert = ErrorAlert(title: "Error \(performedTask)", message: error.localizedDescription, dismissAction: dismissAction)
    }
}
