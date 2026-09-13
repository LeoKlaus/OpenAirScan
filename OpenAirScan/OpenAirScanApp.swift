//
//  OpenAirScanApp.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 20.01.25.
//

import SwiftUI
import EasyErrorHandling

@main
struct OpenAirScanApp: App {
    
    @State private var tappedError: ErrorToast?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withErrorHandling { tappedToast in
                    self.tappedError = tappedToast
                }
        }
    }
}
