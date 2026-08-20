//
//  PresetStore.swift
//  OpenAirScan
//
//  Created on 20.08.25.
//

import Foundation

/// Stores scan presets and the default preset per scanner in `UserDefaults`.
class PresetStore: ObservableObject {

    private static let presetsKey = "scanPresets"
    private static let defaultPresetsKey = "defaultScanPresets"

    @Published private(set) var presets: [ScanPreset]
    /// Maps a scanner uuid to the id of the preset that should be applied by default
    @Published private(set) var defaultPresetIds: [String: UUID]

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: Self.presetsKey), let presets = try? JSONDecoder().decode([ScanPreset].self, from: data) {
            self.presets = presets
        } else {
            self.presets = []
        }

        if let data = userDefaults.data(forKey: Self.defaultPresetsKey), let defaultPresetIds = try? JSONDecoder().decode([String: UUID].self, from: data) {
            self.defaultPresetIds = defaultPresetIds
        } else {
            self.defaultPresetIds = [:]
        }
    }

    /// All presets saved for the given scanner
    func presets(for scannerId: String) -> [ScanPreset] {
        self.presets.filter { $0.scannerId == scannerId }
    }

    /// The preset to apply by default for the given scanner, if any
    func defaultPreset(for scannerId: String) -> ScanPreset? {
        guard let id = self.defaultPresetIds[scannerId] else {
            return nil
        }
        return self.presets.first { $0.id == id }
    }

    func isDefault(_ preset: ScanPreset) -> Bool {
        self.defaultPresetIds[preset.scannerId] == preset.id
    }

    func add(_ preset: ScanPreset) {
        self.presets.append(preset)
        self.persist()
    }

    func delete(_ preset: ScanPreset) {
        self.presets.removeAll { $0.id == preset.id }
        if self.defaultPresetIds[preset.scannerId] == preset.id {
            self.defaultPresetIds[preset.scannerId] = nil
        }
        self.persist()
    }

    /// Marks the given preset as the default for its scanner, or clears the default if it already was.
    func toggleDefault(_ preset: ScanPreset) {
        if self.isDefault(preset) {
            self.defaultPresetIds[preset.scannerId] = nil
        } else {
            self.defaultPresetIds[preset.scannerId] = preset.id
        }
        self.persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(self.presets) {
            self.userDefaults.set(data, forKey: Self.presetsKey)
        }
        if let data = try? JSONEncoder().encode(self.defaultPresetIds) {
            self.userDefaults.set(data, forKey: Self.defaultPresetsKey)
        }
    }
}
