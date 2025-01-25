//
//  IntentButtons.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL

struct IntentButtons: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    @EnvironmentObject var tabStateHandler: TabStateHandler
    
    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings
    
    @State private var progress: Double = 0
    @Binding var isScanning: Bool
    
    var body: some View {
        if self.isScanning {
            VStack {
                ProgressView("Scanning Document...", value: self.progress)
                    .padding(.vertical)
            }
        } else {
            ForEach(capabilities.sourceCapabilities[scanSettings.source]?.supportedIntents ?? [], id: \.rawValue) { intent in
                Button {
                    let settings = ScanSettings(source: self.scanSettings.source, version: capabilities.version ?? scanner.esclVersion ?? "2.1", intent: intent)
                    
                    Task {
                        self.isScanning = true
                        do {
                            try await self.scanner.performScanAndSaveFiles(settings) { progress, _ in
                                self.progress = progress.fractionCompleted
                            }
                            tabStateHandler.currentTab = .documents
                        } catch {
                            errorHandler.handle(error, while: "scanning document")
                        }
                        self.isScanning = false
                        self.progress = 0
                    }
                } label: {
                    switch intent {
                    case .businessCard:
                        Label("Business Card", systemImage: "person.text.rectangle")
                    case .document:
                        Label("Document", systemImage: "doc")
                    case .object:
                        Label("Object", systemImage: "view.3d")
                    case .photo:
                        Label("Photo", systemImage: "photo")
                    case .preview:
                        Label("Preview", systemImage: "document.viewfinder")
                    case .textAndGraphic:
                        Label("Text and Photo", systemImage: "doc.richtext")
                    case .unknown(let str):
                        Text(str)
                    }
                }
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var isScanning = false
    
    List {
        IntentButtons(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, isScanning: $isScanning)
    }
}
