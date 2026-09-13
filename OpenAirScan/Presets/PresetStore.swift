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

    @Published private(set) var presets: [ScanPreset]

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let data = userDefaults.data(forKey: Self.presetsKey), let presets = try? JSONDecoder().decode([ScanPreset].self, from: data) {
            self.presets = presets
        } else {
            self.presets = []
        }
    }

    /// All presets saved for the given scanner
    func presets(for scannerId: String) -> [ScanPreset] {
        self.presets.filter { $0.scannerId == scannerId }
    }

    func add(_ preset: ScanPreset) {
        self.presets.append(preset)
        self.persist()
    }

    func delete(_ preset: ScanPreset) {
        self.presets.removeAll { $0.id == preset.id }
        self.persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(self.presets) {
            self.userDefaults.set(data, forKey: Self.presetsKey)
        }
    }
}
