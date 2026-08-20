//
//  PresetsSection.swift
//  OpenAirScan
//
//  Created on 20.08.25.
//

import SwiftUI
import SwiftESCL

struct PresetsSection: View {

    @EnvironmentObject var presetStore: PresetStore

    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities

    @Binding var scanSettings: ScanSettings

    /// Called after a preset was applied to the scan settings
    let onApply: () -> Void

    var body: some View {
        let presets = presetStore.presets(for: scanner.id)

        if !presets.isEmpty {
            Section {
                ForEach(presets) { preset in
                    Button {
                        preset.apply(to: &scanSettings, capabilities: capabilities)
                        onApply()
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
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Swipe a preset to delete it or make it the default for this scanner.")
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")

    let store = {
        let store = PresetStore(userDefaults: UserDefaults(suiteName: "preview")!)
        store.add(ScanPreset(scannerId: EsclScanner.mock.id, name: "A4 ADF Colour", settings: ScanSettings(source: .adf, version: "2.0")))
        return store
    }()

    List {
        PresetsSection(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings) {}
    }
    .environmentObject(store)
}
#endif
