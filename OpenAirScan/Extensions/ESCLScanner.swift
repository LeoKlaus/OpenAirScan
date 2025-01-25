//
//  ESCLScanner.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import Foundation
import SwiftESCL
import PDFKit

enum NextPageScanError: Error {
    case noValidPDFFound
}

extension EsclScanner {
    public func performScanAndSaveFiles(_ scanSettings: ScanSettings, _ updateProgress: @escaping (Progress, NSKeyValueObservedChange<Double>) -> ()) async throws -> URL {
        let imageData = try await self.performScan(scanSettings, updateProgress)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YY-MM-dd-HH-mm-ss"
        
        var fileURL = URL(filePath: "")
        
        for image in imageData {
            
            fileURL = URL.documentsDirectory.appending(path: "\(formatter.string(from: .now)).\(scanSettings.mimeType?.preferredFilenameExtension ?? "pdf")")
            
            try image.write(to: fileURL)
            
            Self.logger.debug("Saved file \(fileURL.lastPathComponent) to \(fileURL)")
        }
        
        return fileURL
    }
    
    public func performScanAndAppendPages(to fileURL: URL, _ scanSettings: ScanSettings, _ updateProgress: @escaping (Progress, NSKeyValueObservedChange<Double>) -> ()) async throws {
        
        guard let lastDocument = PDFDocument(url: fileURL) else {
            throw NextPageScanError.noValidPDFFound
        }
        
        let scanResults = try await self.performScan(scanSettings, updateProgress)
        
        
        for result in scanResults {
            guard let pdf = PDFDocument(data: result) else {
                break
            }
            lastDocument.addPages(from: pdf)
            
            Self.logger.debug("Added page to \(fileURL)")
        }
        
        lastDocument.write(to: fileURL)
        
        Self.logger.debug("Saved final pdf to \(fileURL)")
    }
}
