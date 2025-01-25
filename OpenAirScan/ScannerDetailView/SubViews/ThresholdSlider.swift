//
//  ThresholdSlider.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 22.01.25.
//

import SwiftUI
import SwiftESCL

struct ThresholdSlider: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        if let thresholdSupport = capabilities.thresholdSupport, scanSettings.threshold != nil {
            SliderWithValueEntry(text: "Threshold", systemImage: "scissors", support: thresholdSupport, value: $scanSettings.threshold)
        } else {
            Button {
                scanSettings.threshold = capabilities.thresholdSupport?.normal ?? 128
            } label: {
                Label("Change Threshold", systemImage: "scissors")
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        ThresholdSlider(capabilities: .mock, scanSettings: $scanSettings)
    }
}
