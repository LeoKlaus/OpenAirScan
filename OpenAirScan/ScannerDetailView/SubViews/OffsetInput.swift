//
//  OffsetInput.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 22.01.25.
//

import SwiftUI
import SwiftESCL

struct OffsetInput: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        VStack(alignment: .leading) {
            Label("Offset", systemImage: "textformat.characters.arrow.left.and.right")
            HStack {
                Text("Left:")
                Spacer()
                TextField(
                    "Left",
                    value: Binding(
                        get: {
                            if let offset = self.scanSettings.offset {
                                offset.width
                            } else {
                                nil as Int?
                            }
                        },
                        set: { newValue in
                            if let newValue {
                                self.scanSettings.offset = IntSize(width: newValue, height:  self.scanSettings.offset?.height ?? 0)
                            } else if self.scanSettings.offset?.height != nil {
                                self.scanSettings.offset = IntSize(width: 0, height:  self.scanSettings.offset?.height ?? 0)
                            } else {
                                self.scanSettings.offset = nil
                            }
                        }),
                    format: .number
                )
                .keyboardType(.numberPad)
                .foregroundStyle(.secondary)
                Text("Top:")
                TextField(
                    "Top",
                    value: Binding(
                        get: {
                            if let offset = self.scanSettings.offset {
                                offset.height
                            } else {
                                nil as Int?
                            }
                        },
                        set: { newValue in
                            if let newValue {
                                self.scanSettings.offset = IntSize(width: self.scanSettings.offset?.width ?? 0, height: newValue)
                            } else if self.scanSettings.offset?.width != nil {
                                self.scanSettings.offset = IntSize(width: self.scanSettings.offset?.width ?? 0, height: 0)
                            } else {
                                self.scanSettings.offset = nil
                            }
                        }),
                    format: .number
                )
                .keyboardType(.numberPad)
                .foregroundStyle(.secondary)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        OffsetInput(capabilities: .mock, scanSettings: $scanSettings)
    }
}
