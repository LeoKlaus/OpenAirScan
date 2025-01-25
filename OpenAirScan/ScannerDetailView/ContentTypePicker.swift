//
//  ContentTypePicker.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

extension ContentType {
    var systemImage: String {
        switch self {
        case .photo:
            "photo"
        case .text:
            "text.page"
        case .textAndPhoto:
            "richtext.page"
        case .lineArt:
            "line.3.horizontal"
        case .magazine:
            "magazine"
        case .halftone:
            "circle.lefthalf.filled.righthalf.striped.horizontal.inverse"
        case .auto:
            "a.circle"
        }
    }
}

struct ContentTypePicker: View {
    
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    var body: some View {
        Picker("Content Type", systemImage: self.scanSettings.contentType?.systemImage ?? "document.badge.gearshape", selection: $scanSettings.contentType) {
            ForEach(Array(capabilities.sourceCapabilities[scanSettings.source]?.contentTypes ?? []), id: \.rawValue) { contentType in
                switch contentType {
                case .photo:
                    Text("Photo").tag(contentType)
                case .text:
                    Text("Text").tag(contentType)
                case .textAndPhoto:
                    Text("Text and Photo").tag(contentType)
                case .lineArt:
                    Text("Lineart").tag(contentType)
                case .magazine:
                    Text("Magazine").tag(contentType)
                case .halftone:
                    Text("Halftone").tag(contentType)
                case .auto:
                    Text("Auto").tag(contentType)
                }
            }
            Text("None").tag(nil as ContentType?)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        ContentTypePicker(capabilities: .mock, scanSettings: $scanSettings)
    }
}
