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
    @EnvironmentObject var presetStore: PresetStore

    let scanner: EsclScanner

    @State private var capabilities: EsclScannerCapabilities?

    @State private var scanSettings: ScanSettings
    @State var currentTask: Task<Sendable, Error>?

    @State private var progress: Double = 0
    @State private var showCustomScan: Bool = false

    init(_ scannerRep: EsclScanner) {
        self.scanner = scannerRep
        self.scanSettings = ScanSettings(source: scannerRep.inputSources.first ?? .platen, version: scannerRep.esclVersion ?? "2.1")
    }

    @Sendable
    func getCapabilities() async {
        do {
            let caps = try await scanner.getCapabilities()
            self.capabilities = caps

            if let defaultPreset = presetStore.defaultPreset(for: scanner.id) {
                defaultPreset.apply(to: &self.scanSettings, capabilities: caps)
            }
        } catch {
            errorHandler.handle(error, while: "getting scanner capabilities")
        }
    }
    
    var body: some View {
        VStack {
            if let capabilities {
                List {
                    if let currentTask {
                        Section {
                            VStack {
                                ProgressView("Scanning Document...", value: self.progress)
                                    .padding(.horizontal)
                                Button(role: .destructive) {
                                    currentTask.cancel()
                                } label: {
                                    Label("Cancel Scan", systemImage: "trash")
                                }
                                .foregroundStyle(.red)
                            }
                        }
                    }
                    
                    SourcePicker(capabilities: capabilities, scanSettings: $scanSettings)
                        .disabled(currentTask != nil)
                    
                    Section {
                        IntentButtons(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, progress: $progress, currentTask: $currentTask)
                            .disabled(currentTask != nil)
                    } header: {
                        Text("Quick Scan")
                    } footer: {
                        Text("Quick scan uses the optimized defaults for the selected content type.")
                    }
                    
                    NavigationLink(destination: CustomScanView(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, currentTask: $currentTask)) {
                        Label("Custom Scan", systemImage: "slider.horizontal.3")
                    }
                    .disabled(currentTask != nil)

                    PresetsSection(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, progress: $progress, currentTask: $currentTask) {
                        self.showCustomScan = true
                    }
                    .disabled(currentTask != nil)
                }
                .navigationDestination(isPresented: $showCustomScan) {
                    CustomScanView(scanner: scanner, capabilities: capabilities, scanSettings: $scanSettings, currentTask: $currentTask)
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
    .environmentObject(PresetStore())
    .withErrorHandling()
}
#endif
