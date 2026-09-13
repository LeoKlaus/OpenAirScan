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
    @EnvironmentObject var presetStore: PresetStore

    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities

    @Binding var scanSettings: ScanSettings

    @State private var showAdvancedSettings: Bool = false

    @State private var showSavePresetAlert: Bool = false
    @State private var presetName: String = ""
    
    @State private var progress: Double = 0
    @Binding var currentTask: Task<Sendable, Error>?
    
    @State private var showNextPageDialog: Bool = false
    @State private var lastSavedFileURL: URL? = nil
    
    func scanDocument() async {
        do {
            self.lastSavedFileURL = try await self.scanner.performScanAndSaveFiles(self.scanSettings) { progress, _ in
                Task { @MainActor in
                    self.progress = progress.fractionCompleted
                }
            }
            if self.scanSettings.mimeType == .pdf && self.scanSettings.source != .adf && self.scanSettings.source != .adfDuplex {
                self.showNextPageDialog = true
            } else {
                tabStateHandler.currentTab = .documents
            }
        } catch {
            if !Task.isCancelled {
                errorHandler.handle(error, while: "scanning document")
            }
        }
        self.progress = 0
        self.currentTask = nil
    }
    
    func scanAndAppendPages() async {
        guard let url = self.lastSavedFileURL else {
            errorHandler.handle("Couldn't get the URL of the last saved file", while: "scanning next page")
            return
        }
        
        do {
            try await self.scanner.performScanAndAppendPages(to: url, scanSettings) { progress, _ in
                Task { @MainActor in
                    self.progress = progress.fractionCompleted
                }
            }
            
            self.showNextPageDialog = true
        } catch {
            if !Task.isCancelled {
                errorHandler.handle(error, while: "scanning document")
            }
        }
        
        self.progress = 0
        self.currentTask = nil
    }
    
    var body: some View {
        List {
            if let currentTask {
                VStack {
                    ProgressView("Scanning document...", value: self.progress)
                        .padding(.vertical)
                    Button(role: .destructive) {
                        currentTask.cancel()
                    } label: {
                        Label("Cancel scan", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
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
                .disabled(currentTask != nil)
                Section("Advanced Settings", isExpanded: $showAdvancedSettings) {
                    OffsetInput(capabilities: capabilities, scanSettings: $scanSettings)
                    BrightnessSlider(capabilities: capabilities, scanSettings: $scanSettings)
                    ContrastSlider(capabilities: capabilities, scanSettings: $scanSettings)
                    ThresholdSlider(capabilities: capabilities, scanSettings: $scanSettings)
                }
                .disabled(currentTask != nil)
                Section {
                    Button {
                        self.presetName = ""
                        self.showSavePresetAlert = true
                    } label: {
                        Label("Save as preset", systemImage: "square.and.arrow.down")
                    }
                } footer: {
                    Text("Saves the current settings as a preset for this scanner.")
                }
            }
        }
        .listStyle(.sidebar)
        .alert("Save Preset", isPresented: $showSavePresetAlert) {
            TextField("Preset name", text: $presetName)
            Button("Save") {
                let name = self.presetName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    self.presetStore.add(ScanPreset(scannerId: self.scanner.id, name: name, settings: self.scanSettings))
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Scan") {
                    self.scanSettings.calculateOffSet(for: self.scanner)
                    
                    self.currentTask = Task(operation: scanDocument)
                }
                .disabled(currentTask != nil)
            }
        }
        .confirmationDialog("Scan more pages?", isPresented: $showNextPageDialog) {
            Button("Yes (put the next page in the scanner before tapping)") {
                self.currentTask = Task(operation: scanAndAppendPages)
            }
            Button("No (save scan)") {
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
    @Previewable @State var task: Task<Sendable, Error>?
    
    NavigationStack {
        CustomScanView(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, currentTask: $task)
    }
    .environmentObject(PresetStore())
}
#endif
