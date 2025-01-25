//
//  ScannerRepresentation+Mock.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftESCL
import Foundation

class MockScannerRep: EsclScanner {
    
    init() {
        try! super.init(
            hostname: "epson.local",
            location: "Office",
            model: "EPSON ET-4800 Series",
            iconUrl: "https://epson.local.:443/PRESENTATION/AIRPRINT/PRINTER_128.PNG",
            root: "eSCL",
            esclVersion: "2.9",
            adminUrl: "http://epson.local.:80/PRESENTATION/BONJOUR",
            mimeTypes: [.pdf, .jpeg],
            colorSpaces: [.binary, .color, .grayscale],
            inputSources: [.adf, .platen],
            duplex: false,
            usePlainText: false
        )
    }
    
    override func getCapabilities() async throws -> EsclScannerCapabilities {
        try await Task.sleep(for: .seconds(1))
        return .mock
    }
    
    override func performScan(_ scanSettings: ScanSettings, _ updateProgress: @escaping (Progress, NSKeyValueObservedChange<Double>) -> () = { _,_ in }) async throws -> [Data] {
        
        try await Task.sleep(for: .seconds(10))
        
        return []
    }
}

extension EsclScanner {
    static let mock = MockScannerRep()
}
