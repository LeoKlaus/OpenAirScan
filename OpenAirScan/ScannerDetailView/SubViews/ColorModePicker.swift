//
//  ColorModePicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct ColorModePicker: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        Picker("Color Mode", systemImage: "circle.dotted.and.circle", selection: $scanSettings.colorMode) {
            ForEach(Array(capabilities.sourceCapabilities[scanSettings.source]?.colorModes ?? []), id: \.rawValue) { colorMode in
                switch colorMode {
                case .blackAndWhite:
                    Text("Black and White").tag(colorMode)
                case .grayscale8:
                    Text("Grayscale").tag(colorMode)
                case .grayscale16:
                    Text("Grayscale (16-bit)").tag(colorMode)
                case .rgb24:
                    Text("Color").tag(colorMode)
                case .rgb48:
                    Text("Color (16-bit)").tag(colorMode)
                }
            }
            Text("None").tag(nil as ColorMode?)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        ColorModePicker(capabilities: .mock, scanSettings: $scanSettings)
    }
}
#endif
