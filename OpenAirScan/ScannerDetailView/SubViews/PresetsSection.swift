//
//  PresetsSection.swift
//  OpenAirScan
//
//  Created on 20.08.25.
//

import SwiftUI
import SwiftESCL
import EasyErrorHandling

struct PresetsSection: View {
    @EnvironmentObject var tabStateHandler: TabStateHandler
    @EnvironmentObject var presetStore: PresetStore

    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities

    @Binding var scanSettings: ScanSettings
    @Binding var progress: Double
    @Binding var currentTask: Task<Sendable, Error>?

    /// Called to open the custom scan view with the preset applied
    let onEdit: () -> Void

    @StateObject private var scanFlow: ScanFlowController

    init(scanner: EsclScanner, capabilities: EsclScannerCapabilities, scanSettings: Binding<ScanSettings>, progress: Binding<Double>, currentTask: Binding<Task<Sendable, Error>?>, onEdit: @escaping () -> Void) {
        self.scanner = scanner
        self.capabilities = capabilities
        self._scanSettings = scanSettings
        self._progress = progress
        self._currentTask = currentTask
        self.onEdit = onEdit
        self._scanFlow = StateObject(wrappedValue: ScanFlowController(scanner: scanner))
    }

    func scanDocument(_ preset: ScanPreset) async {

        preset.apply(to: &self.scanSettings, capabilities: capabilities)

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
        let presets = presetStore.presets(for: scanner.id)

        if !presets.isEmpty {
            Section {
                ForEach(presets) { preset in
                    Button(preset.name, systemImage: "list.bullet.rectangle") {
                        self.currentTask = Task {
                            await self.scanDocument(preset)
                        }
                    }
                    
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            presetStore.delete(preset)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Tap a preset to scan with its settings. Swipe left to delete it.")
            }
            .scanMorePagesDialog(isPresented: $scanFlow.showNextPageDialog) {
                self.currentTask = Task {
                    await self.scanAndAppendPages()
                }
            } onDone: {
                self.scanFlow.discardPendingScan()
                withAnimation {
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
