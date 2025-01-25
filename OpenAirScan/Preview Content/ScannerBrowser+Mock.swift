//
//  ScannerBrowser+Mock.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftESCL

class MockScannerBrowser: ScannerBrowser {
    
    override func startDiscovery() {
        Task {
            try await Task.sleep(for: .seconds(1))
            self.discovered.append(.mock)
        }
    }
    
}

extension ScannerBrowser {
    static let mock = MockScannerBrowser()
}
