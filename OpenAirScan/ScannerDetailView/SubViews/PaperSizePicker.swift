//
//  PaperSizePicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct PaperSizePicker: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
            Picker("Paper Size", systemImage: "doc.badge.gearshape", selection: $scanSettings.size) {
                Text("DIN A4").tag(PaperSize.a4)
                Text("DIN A5").tag(PaperSize.a5)
                Text("DIN A6").tag(PaperSize.a6)
                
                Text("Letter").tag(PaperSize.letter)
                Text("Legal").tag(PaperSize.legal)
                
                Text("Custom").tag(PaperSize.custom(width: 1000, height: 1000))
            }
            .onAppear {
                if self.scanSettings.size == nil {
                    self.scanSettings.size = PaperSize.a4
                }
            }
            if case .custom = self.scanSettings.size {
                HStack {
                    Text("Width:")
                    Spacer()
                    TextField(
                        "Width",
                        value: Binding(
                            get: {
                                Int(self.scanSettings.size?.rawValue.width ?? 0)
                            },
                            set: { newValue in
                                self.scanSettings.size = .custom(width: newValue, height: Int(self.scanSettings.size?.rawValue.height ?? 0))
                            }),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .foregroundStyle(.secondary)
                    Text("Height:")
                    TextField(
                        "Height",
                        value: Binding(
                            get: {
                                Int(self.scanSettings.size?.rawValue.height ?? 0)
                            },
                            set: { newValue in
                                self.scanSettings.size = .custom(width: Int(self.scanSettings.size?.rawValue.width ?? 0), height: newValue)
                            }),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                    .foregroundStyle(.secondary)
                }
            }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        PaperSizePicker(capabilities: .mock, scanSettings: $scanSettings)
    }
}
#endif
