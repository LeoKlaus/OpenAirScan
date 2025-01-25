//
//  ScannerDetailView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct ScannerDetailView: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    
    let scanner: EsclScanner
    
    @State private var capabilities: EsclScannerCapabilities?
    
    @State private var scanSettings: ScanSettings
    @State var currentTask: Task<Sendable, Error>?
    
    init(_ scannerRep: EsclScanner) {
        self.scanner = scannerRep
        self.scanSettings = ScanSettings(source: scannerRep.inputSources.first ?? .platen, version: scannerRep.esclVersion ?? "2.1")
    }
    
    @Sendable
    func getCapabilities() async {
        do {
            let caps = try await scanner.getCapabilities()
            self.capabilities = caps
        } catch {
            errorHandler.handle(error, while: "getting scanner capabilities")
        }
    }
    
    var body: some View {
        VStack {
            if let capabilities {
                List {
                    SourcePicker(capabilities: capabilities, scanSettings: $scanSettings)
                        .disabled(currentTask != nil)
                    
                    Section {
                        IntentButtons(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, currentTask: $currentTask)
                    } header: {
                        Text("Quick Scan")
                    } footer: {
                        Text("Quick scan uses the optimized defaults for the selected content type.")
                    }
                    
                    NavigationLink(destination: CustomScanView(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, currentTask: $currentTask)) {
                        Label("Custom Scan", systemImage: "slider.horizontal.3")
                    }
                    .disabled(currentTask != nil)
                }
            } else {
                Text("Getting scanner capabilities...")
                ProgressView()
                    .task(getCapabilities)
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    NavigationStack {
        ScannerDetailView(.mock)
    }
    .withErrorHandling()
}
#endif
