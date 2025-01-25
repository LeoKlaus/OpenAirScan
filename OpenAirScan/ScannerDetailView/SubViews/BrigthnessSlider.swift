//
//  BrigthnessSlider.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 22.01.25.
//

import SwiftUI
import SwiftESCL

struct BrightnessSlider: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        if let brightnessSupport = capabilities.brightnessSupport, scanSettings.brightness != nil {
            SliderWithValueEntry(text: "Brightness", systemImage: "sun.max", support: brightnessSupport, value: $scanSettings.brightness)
        } else {
            Button {
                scanSettings.brightness = capabilities.brightnessSupport?.normal ?? 128
            } label: {
                Label("Change Brightness", systemImage: "sun.max")
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        BrightnessSlider(capabilities: .mock, scanSettings: $scanSettings)
    }
}
