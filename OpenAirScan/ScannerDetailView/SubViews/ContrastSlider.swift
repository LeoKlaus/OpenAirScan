//
//  ContrastSlider.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 22.01.25.
//

import SwiftUI
import SwiftESCL

struct ContrastSlider: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        if let contrastSupport = capabilities.contrastSupport, scanSettings.contrast != nil {
            SliderWithValueEntry(text: "Contrast", systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal", support: contrastSupport, value: $scanSettings.contrast)
        } else {
            Button {
                scanSettings.contrast = capabilities.contrastSupport?.normal ?? 128
            } label: {
                Label("Change Contrast", systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal")
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        ContrastSlider(capabilities: .mock, scanSettings: $scanSettings)
    }
}
#endif
