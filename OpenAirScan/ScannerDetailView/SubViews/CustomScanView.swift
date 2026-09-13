//
//  CustomScanView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL
import PDFKit
import EasyErrorHandling

struct CustomScanView: View {
    
    @Environment(\.dismiss) var dismiss
    
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

    @StateObject private var scanFlow: ScanFlowController

    init(scanner: EsclScanner, capabilities: EsclScannerCapabilities, scanSettings: Binding<ScanSettings>, currentTask: Binding<Task<Sendable, Error>?>) {
        self.scanner = scanner
        self.capabilities = capabilities
        self._scanSettings = scanSettings
        self._currentTask = currentTask
        self._scanFlow = StateObject(wrappedValue: ScanFlowController(scanner: scanner))
    }

    func scanDocument() async {
        let finished = await scanFlow.scan(self.scanSettings, progress: $progress)
        if finished {
            withAnimation {
                tabStateHandler.currentTab = .documents
            }
        }
        self.progress = 0
        self.currentTask = nil
    }

    func scanAndAppendPages() async {
        await scanFlow.appendPages(progress: $progress)
        self.progress = 0
        self.currentTask = nil
    }
    
    var body: some View {
        List {
            if let currentTask {
                Section {
                    ProgressView("Scanning document...", value: self.progress)
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
                    self.dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Scan") {
                    self.scanSettings.calculateOffSet(for: self.scanner)
                    
                    self.currentTask = Task(operation: scanDocument)
                }
                .disabled(currentTask != nil)
                .scanMorePagesDialog(isPresented: $scanFlow.showNextPageDialog) {
                    self.currentTask = Task(operation: scanAndAppendPages)
                } onDone: {
                    self.scanFlow.discardPendingScan()
                    withAnimation {
                        self.tabStateHandler.currentTab = .documents
                    }
                }
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
