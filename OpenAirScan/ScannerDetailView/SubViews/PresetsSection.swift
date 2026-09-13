//
//  PresetsSection.swift
//  OpenAirScan
//
//  Created on 20.08.25.
//

import SwiftUI
import SwiftESCL

struct PresetsSection: View {

    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var tabStateHandler: TabStateHandler
    @EnvironmentObject var presetStore: PresetStore

    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities

    @Binding var scanSettings: ScanSettings
    @Binding var progress: Double
    @Binding var currentTask: Task<Sendable, Error>?

    /// Called to open the custom scan view with the preset applied
    let onEdit: () -> Void

    @State private var showNextPageDialog: Bool = false
    @State private var lastSavedFileURL: URL? = nil

    func scanDocument(_ preset: ScanPreset) async {

        preset.apply(to: &self.scanSettings, capabilities: capabilities)

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
            try await self.scanner.performScanAndAppendPages(to: url, self.scanSettings) { progress, _ in
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
        let presets = presetStore.presets(for: scanner.id)

        if !presets.isEmpty {
            Section {
                ForEach(presets) { preset in
                    Button {
                        self.currentTask = Task {
                            await self.scanDocument(preset)
                        }
                    } label: {
                        HStack {
                            Label(preset.name, systemImage: "list.bullet.rectangle")
                            if presetStore.isDefault(preset) {
                                Spacer()
                                Text("Default")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.primary)
                    .swipeActions(edge: .leading) {
                        Button {
                            presetStore.toggleDefault(preset)
                        } label: {
                            if presetStore.isDefault(preset) {
                                Label("Clear Default", systemImage: "star.slash")
                            } else {
                                Label("Make Default", systemImage: "star")
                            }
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            presetStore.delete(preset)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        Button {
                            preset.apply(to: &scanSettings, capabilities: capabilities)
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "slider.horizontal.3")
                        }
                        .tint(.blue)
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Tap a preset to scan with its settings. Swipe a preset to edit it in the custom scan view, delete it or make it the default for this scanner.")
            }
            .confirmationDialog("Scan More Pages?", isPresented: $showNextPageDialog) {
                Button("Yes (put the next page in the scanner before tapping)") {
                    self.currentTask = Task {
                        await self.scanAndAppendPages()
                    }
                }
                Button("No (save scan)") {
                    self.lastSavedFileURL = nil
                    self.tabStateHandler.currentTab = .documents
                }
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var progress: Double = 0
    @Previewable @State var task: Task<Sendable, Error>?

    let store = {
        let store = PresetStore(userDefaults: UserDefaults(suiteName: "preview")!)
        store.add(ScanPreset(scannerId: EsclScanner.mock.id, name: "A4 ADF Colour", settings: ScanSettings(source: .adf, version: "2.0")))
        return store
    }()

    List {
        PresetsSection(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, progress: $progress, currentTask: $task) {}
    }
    .environmentObject(store)
    .withErrorHandling()
}
#endif
