//
//  CustomScanView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct CustomScanView: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var tabStateHandler: TabStateHandler
    
    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    @State private var showAdvancedSettings: Bool = false
    
    @State private var progress: Double = 0
    @State private var isScanning: Bool = false
    
    var body: some View {
        List {
            if isScanning {
                VStack {
                    ProgressView("Scanning Document...", value: self.progress)
                        .padding(.vertical)
                }
            } else {
                Section {
                    SourcePicker(capabilities: capabilities, scanSettings: $scanSettings)
                    FileTypePicker(capabilites: capabilities, scanSettings: $scanSettings)
                    ContentTypePicker(capabilities: capabilities, scanSettings: $scanSettings)
                    ColorModePicker(capabilities: capabilities, scanSettings: $scanSettings)
                    ResolutionPicker(capabilities: capabilities, scanSettings: $scanSettings)
                    PaperSizePicker(capabilities: capabilities, scanSettings: $scanSettings)
                } footer: {
                    if case .custom = self.scanSettings.size {
                        Text("Size and offset are measured in 300ths of an inch.")
                    }
                }
                if #available(iOS 17.0, *) {
                    Section("Advanced Settings", isExpanded: $showAdvancedSettings) {
                        OffsetInput(capabilities: capabilities, scanSettings: $scanSettings)
                        BrightnessSlider(capabilities: capabilities, scanSettings: $scanSettings)
                        ContrastSlider(capabilities: capabilities, scanSettings: $scanSettings)
                        ThresholdSlider(capabilities: capabilities, scanSettings: $scanSettings)
                    }
                } else {
                    Section("Advanced Settings") {
                        OffsetInput(capabilities: capabilities, scanSettings: $scanSettings)
                        BrightnessSlider(capabilities: capabilities, scanSettings: $scanSettings)
                        ContrastSlider(capabilities: capabilities, scanSettings: $scanSettings)
                        ThresholdSlider(capabilities: capabilities, scanSettings: $scanSettings)
                    }
                }
            }
        }
        .disabled(isScanning)
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Scan") {
                    // TODO: Implement scanning here
                    
                    self.scanSettings.calculateOffSet(for: self.scanner)
                    
                    Task {
                        self.isScanning = true
                        do {
                            try await self.scanner.performScanAndSaveFiles(self.scanSettings) { progress, _ in
                                self.progress = progress.fractionCompleted
                            }
                            tabStateHandler.currentTab = .documents
                        } catch {
                            errorHandler.handle(error, while: "scanning document")
                        }
                        self.isScanning = false
                        self.progress = 0
                    }
                }
                .disabled(isScanning)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    NavigationStack {
        CustomScanView(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings)
    }
}
