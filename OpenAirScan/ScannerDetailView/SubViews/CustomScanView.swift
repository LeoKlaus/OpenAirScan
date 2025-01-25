//
//  CustomScanView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL
import PDFKit

struct CustomScanView: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var tabStateHandler: TabStateHandler
    
    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    @State private var showAdvancedSettings: Bool = false
    
    @State private var progress: Double = 0
    @State private var isScanning: Bool = false
    
    @State private var showNextPageDialog: Bool = false
    @State private var lastSavedFileURL: URL? = nil
    
    func scanDocument() async {
        self.isScanning = true
        do {
            self.lastSavedFileURL = try await self.scanner.performScanAndSaveFiles(self.scanSettings) { progress, _ in
                self.progress = progress.fractionCompleted
            }
            if self.scanSettings.mimeType == .pdf && self.scanSettings.source != .adf && self.scanSettings.source != .adfDuplex {
                self.showNextPageDialog = true
            } else {
                tabStateHandler.currentTab = .documents
            }
        } catch {
            errorHandler.handle(error, while: "scanning document")
        }
        self.isScanning = false
        self.progress = 0
    }
    
    func scanAndAppendPages() async {
        guard let url = self.lastSavedFileURL else {
            errorHandler.handle("Couldn't get the URL of the last saved file", while: "scanning next page")
            return
        }
        
        
        
        self.isScanning = true
        do {
            try await self.scanner.performScanAndAppendPages(to: url, scanSettings) { progress, _ in
                self.progress = progress.fractionCompleted
            }
            
            self.showNextPageDialog = true
        } catch {
            errorHandler.handle(error, while: "scanning document")
        }
        self.isScanning = false
        self.progress = 0
    }
    
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
                    self.scanSettings.calculateOffSet(for: self.scanner)
                    
                    Task(operation: scanDocument)
                }
                .disabled(isScanning)
            }
        }
        .confirmationDialog("Scan more pages?", isPresented: $showNextPageDialog) {
            Button("Yes (put the next page in the scanner before tapping)") {
                Task(operation: scanAndAppendPages)
            }
            Button("No (Save Scan)") {
                self.lastSavedFileURL = nil
                self.tabStateHandler.currentTab = .documents
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    NavigationStack {
        CustomScanView(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings)
    }
}
#endif
