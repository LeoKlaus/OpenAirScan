//
//  FileTypePicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct FileTypePicker: View {
    
    let capabilites: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        Picker("File Type", systemImage: "filemenu.and.selection", selection: $scanSettings.mimeType) {
            ForEach(Array(capabilites.sourceCapabilities[scanSettings.source]?.documentFormats ?? []), id: \.identifier) { fileType in
                Text(fileType.localizedDescription ?? fileType.identifier).tag(fileType)
            }
        }
        .onAppear {
            if self.scanSettings.mimeType == nil {
                self.scanSettings.mimeType = capabilites.sourceCapabilities[scanSettings.source]?.documentFormats.first
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        FileTypePicker(capabilites: .mock, scanSettings: $scanSettings)
    }
}
