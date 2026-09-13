//
//  ScanPreset.swift
//  OpenAirScan
//
//  Created on 20.08.25.
//

import Foundation
import UniformTypeIdentifiers
import SwiftESCL

/// A named, persistable snapshot of scan settings for a specific scanner.
struct ScanPreset: Identifiable, Codable, Hashable {

    var id: UUID
    /// The uuid of the scanner this preset belongs to
    var scannerId: String
    var name: String

    var source: String
    var mimeType: String?
    var resolution: Int?
    var colorMode: String?
    var contentType: String?
    var paperWidth: Int?
    var paperHeight: Int?
    var offsetX: Int?
    var offsetY: Int?
    var brightness: Int?
    var contrast: Int?
    var threshold: Int?

    init(id: UUID = UUID(), scannerId: String, name: String, settings: ScanSettings) {
        self.id = id
        self.scannerId = scannerId
        self.name = name

        self.source = settings.source.rawValue
        self.mimeType = settings.mimeType?.identifier
        self.resolution = settings.resolution
        self.colorMode = settings.colorMode?.rawValue
        self.contentType = settings.contentType?.rawValue
        self.paperWidth = settings.size?.rawValue.width
        self.paperHeight = settings.size?.rawValue.height
        self.offsetX = settings.offset?.width
        self.offsetY = settings.offset?.height
        self.brightness = settings.brightness
        self.contrast = settings.contrast
        self.threshold = settings.threshold
    }

    /**
     Apply this preset to the given scan settings.
     - Parameter settings: The settings to apply the preset to.
     - Parameter capabilities: If given, the source is validated against the scanners capabilities and falls back to the first supported source.
     */
    func apply(to settings: inout ScanSettings, capabilities: EsclScannerCapabilities? = nil) {
        if let source = InputSource(rawValue: self.source) {
            settings.source = source
        }

        if let capabilities, capabilities.sourceCapabilities[settings.source] == nil, let fallback = capabilities.sourceCapabilities.keys.first {
            settings.source = fallback
        }

        settings.mimeType = self.mimeType.flatMap { UTType($0) }
        settings.resolution = self.resolution
        settings.colorMode = self.colorMode.flatMap { ColorMode(rawValue: $0) }
        settings.contentType = self.contentType.flatMap { ContentType(rawValue: $0) }

        if let paperWidth, let paperHeight {
            settings.size = PaperSize(rawValue: IntSize(width: paperWidth, height: paperHeight))
        } else {
            settings.size = nil
        }

        if let offsetX, let offsetY {
            settings.offset = IntSize(width: offsetX, height: offsetY)
        } else {
            settings.offset = nil
        }

        settings.brightness = self.brightness
        settings.contrast = self.contrast
        settings.threshold = self.threshold
    }
}
