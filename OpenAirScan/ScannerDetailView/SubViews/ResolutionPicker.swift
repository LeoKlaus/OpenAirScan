//
//  ResolutionPicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct ResolutionPicker: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        Picker("Resolution", systemImage: "square.resize", selection: $scanSettings.resolution) {
            ForEach(capabilities.sourceCapabilities[scanSettings.source]?.supportedResolutions ?? [], id: \.self) { resolution in
                Text("\(resolution) DPI").tag(resolution)
            }
        }
        .onAppear {
            if self.scanSettings.resolution == nil {
                self.scanSettings.resolution = capabilities.sourceCapabilities[scanSettings.source]?.supportedResolutions.first
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        ResolutionPicker(capabilities: .mock, scanSettings: $scanSettings)
    }
}
#endif
