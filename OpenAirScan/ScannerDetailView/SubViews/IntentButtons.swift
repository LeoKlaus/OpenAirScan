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
    @Binding var currentTask: Task<Sendable, Error>?
    
    func scanDocument(_ intent: Intent) async {
        
        let settings = ScanSettings(source: self.scanSettings.source, version: capabilities.version ?? scanner.esclVersion ?? "2.1", intent: intent)
        
        do {
            _ = try await self.scanner.performScanAndSaveFiles(settings) { progress, _ in
                self.progress = progress.fractionCompleted
            }
            tabStateHandler.currentTab = .documents
        } catch {
            if !Task.isCancelled {
                errorHandler.handle(error, while: "scanning document")
            }
        }
        
        self.progress = 0
        self.currentTask = nil
    }
    
    var body: some View {
        if let currentTask {
            VStack {
                ProgressView("Scanning Document...", value: self.progress)
                    .padding(.horizontal)
                Button(role: .destructive) {
                    currentTask.cancel()
                } label: {
                    Label("Cancel Scan", systemImage: "trash")
                }
                .foregroundStyle(.red)
            }
        } else {
            ForEach(capabilities.sourceCapabilities[scanSettings.source]?.supportedIntents ?? [], id: \.rawValue) { intent in
                Button {
                    self.currentTask = Task {
                        await self.scanDocument(intent)
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

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var task: Task<any Sendable, Error>?
    
    List {
        IntentButtons(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, currentTask: $task)
    }
    .withErrorHandling()
}

@available(iOS 17.0, *)
#Preview("While scanning") {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var task: Task<Sendable, Error>? = Task {
        while true {
            try await Task.sleep(for: .seconds(1))
            if Task.isCancelled {
                throw ScanJobError.cancelled
            }
        }
    }
    
    List {
        IntentButtons(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, currentTask: $task)
    }
    .withErrorHandling()
}
#endif
