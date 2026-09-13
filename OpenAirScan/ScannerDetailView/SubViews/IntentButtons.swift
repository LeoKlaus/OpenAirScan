//
//  IntentButtons.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftUI
import SwiftESCL
import EasyErrorHandling

struct IntentButtons: View {
    @EnvironmentObject var tabStateHandler: TabStateHandler
    
    let scanner: EsclScanner
    let capabilities: EsclScannerCapabilities
    
    @Binding var scanSettings: ScanSettings

    @Binding var progress: Double
    @Binding var currentTask: Task<Sendable, Error>?

    @StateObject private var scanFlow: ScanFlowController

    init(scanner: EsclScanner, capabilities: EsclScannerCapabilities, scanSettings: Binding<ScanSettings>, progress: Binding<Double>, currentTask: Binding<Task<Sendable, Error>?>) {
        self.scanner = scanner
        self.capabilities = capabilities
        self._scanSettings = scanSettings
        self._progress = progress
        self._currentTask = currentTask
        self._scanFlow = StateObject(wrappedValue: ScanFlowController(scanner: scanner))
    }

    func scanDocument(_ intent: Intent) async {

        let settings = ScanSettings(source: self.scanSettings.source, version: capabilities.version ?? scanner.esclVersion ?? "2.1", intent: intent)

        let finished = await scanFlow.scan(settings, progress: $progress)
        if finished {
            withAnimation {
                tabStateHandler.currentTab = .documents
            }
        }

        self.progress = 0
        self.currentTask = nil
    }

    func scanAndAppendPages() async {
        await scanFlow.appendPages(progress: $progress)

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
        .scanMorePagesDialog(isPresented: $scanFlow.showNextPageDialog) {
            self.currentTask = Task {
                await self.scanAndAppendPages()
            }
        } onDone: {
            self.scanFlow.discardPendingScan()
            withAnimation {
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
