//
//  SourcePicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct SourcePicker: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        Picker("Source", systemImage: "scanner", selection: $scanSettings.source) {
            ForEach(Array(capabilities.sourceCapabilities.keys), id: \.self) { source in
                switch source {
                case .adf:
                    Text("Document Feeder").tag(source)
                case .adfDuplex:
                    Text("Document Feeder (Duplex)").tag(source)
                case .camera:
                    Text("Camera").tag(source)
                case .platen:
                    Text("Flatbed").tag(source)
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        SourcePicker(capabilities: .mock, scanSettings: $scanSettings)
    }
}
