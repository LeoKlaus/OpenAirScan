//
//  OpenAirScanApp.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 20.01.25.
//

import SwiftUI

@main
struct OpenAirScanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withErrorHandling()
        }
    }
}
