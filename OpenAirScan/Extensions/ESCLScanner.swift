//
//  ESCLScanner.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import Foundation
import SwiftESCL

extension EsclScanner {
    public func performScanAndSaveFiles(_ scanSettings: ScanSettings, _ updateProgress: @escaping (Progress, NSKeyValueObservedChange<Double>) -> ()) async throws {
        let imageData = try await self.performScan(scanSettings, updateProgress)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YY-MM-dd-HH-mm-ss"
        
        for image in imageData {
            
            let url = URL.documentsDirectory.appending(path: "\(formatter.string(from: .now)).\(scanSettings.mimeType?.preferredFilenameExtension ?? "pdf")")
            
            try image.write(to: url)
            
            Self.logger.debug("Saved file \(url.lastPathComponent) to \(url)")
        }
    }
}
