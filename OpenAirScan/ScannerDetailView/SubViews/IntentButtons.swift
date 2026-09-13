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

    @Binding var progress: Double
    @Binding var currentTask: Task<Sendable, Error>?

    @State private var showNextPageDialog: Bool = false
    @State private var lastSavedFileURL: URL? = nil
    @State private var lastUsedSettings: ScanSettings? = nil

    func scanDocument(_ intent: Intent) async {

        let settings = ScanSettings(source: self.scanSettings.source, version: capabilities.version ?? scanner.esclVersion ?? "2.1", intent: intent)
        self.lastUsedSettings = settings

        do {
            self.lastSavedFileURL = try await self.scanner.performScanAndSaveFiles(settings) { progress, _ in
                Task { @MainActor in
                    self.progress = progress.fractionCompleted
                }
            }
            if settings.mimeType == .pdf && settings.source != .adf && settings.source != .adfDuplex {
                self.showNextPageDialog = true
            } else {
                tabStateHandler.currentTab = .documents
            }
        } catch {
            if !Task.isCancelled {
                errorHandler.handle(error, while: "scanning document")
            }
        }

        self.progress = 0
        self.currentTask = nil
    }

    func scanAndAppendPages() async {
        guard let url = self.lastSavedFileURL, let settings = self.lastUsedSettings else {
            errorHandler.handle("Couldn't get the URL of the last saved file", while: "scanning next page")
            return
        }

        do {
            try await self.scanner.performScanAndAppendPages(to: url, settings) { progress, _ in
                Task { @MainActor in
                    self.progress = progress.fractionCompleted
                }
            }

            self.showNextPageDialog = true
        } catch {
            if !Task.isCancelled {
                errorHandler.handle(error, while: "scanning document")
            }
        }

        self.progress = 0
        self.currentTask = nil
    }

    var body: some View {
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
        .confirmationDialog("Scan more pages?", isPresented: $showNextPageDialog) {
            Button("Yes (put the next page in the scanner before tapping)") {
                self.currentTask = Task {
                    await self.scanAndAppendPages()
                }
            }
            Button("No (save scan)") {
                self.lastSavedFileURL = nil
                self.lastUsedSettings = nil
                self.tabStateHandler.currentTab = .documents
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var task: Task<any Sendable, Error>?
    @Previewable @State var progress: Double = 0
    
    List {
        IntentButtons(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, progress: $progress, currentTask: $task)
    }
    .withErrorHandling()
}

@available(iOS 17.0, *)
#Preview("While scanning") {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    @Previewable @State var progress: Double = 0.4
    @Previewable @State var task: Task<Sendable, Error>? = Task {
        while true {
            try await Task.sleep(for: .seconds(1))
            if Task.isCancelled {
                throw ScanJobError.cancelled
            }
        }
    }
    
    List {
        IntentButtons(scanner: .mock, capabilities: .mock, scanSettings: $scanSettings, progress: $progress, currentTask: $task)
            .disabled(task != nil)
    }
    .withErrorHandling()
}
#endif
