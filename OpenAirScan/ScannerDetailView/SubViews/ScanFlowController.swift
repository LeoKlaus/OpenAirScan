//
//  ScanFlowController.swift
//  OpenAirScan
//

import SwiftUI
import SwiftESCL
import EasyErrorHandling

/// Drives a scan-and-optionally-append-more-pages flow shared by Quick Scan, Presets and Custom Scan.
@MainActor
final class ScanFlowController: ObservableObject {

    @Published var showNextPageDialog = false

    private let scanner: EsclScanner
    private var lastSavedFileURL: URL?
    private var lastSettings: ScanSettings?

    init(scanner: EsclScanner) {
        self.scanner = scanner
    }

    /// Scans and saves a new file. Returns `true` once the caller should move on (e.g. switch to the documents tab);
    /// returns `false` if more pages can still be appended (`showNextPageDialog` is set) or the scan failed.
    func scan(_ settings: ScanSettings, progress: Binding<Double>) async -> Bool {
        do {
            let url = try await scanner.performScanAndSaveFiles(settings) { newProgress, _ in
                Task { @MainActor in progress.wrappedValue = newProgress.fractionCompleted }
            }
            self.lastSavedFileURL = url
            self.lastSettings = settings

            if settings.mimeType == .pdf && settings.source != .adf && settings.source != .adfDuplex {
                self.showNextPageDialog = true
                return false
            }
            return true
        } catch {
            if !Task.isCancelled {
                ErrorHandler.shared.handle(error, while: "scanning document")
            }
            return false
        }
    }

    func appendPages(progress: Binding<Double>) async {
        guard let url = lastSavedFileURL, let settings = lastSettings else {
            ErrorHandler.shared.handle("Couldn't get the URL of the last saved file", while: "scanning next page")
            return
        }

        do {
            try await scanner.performScanAndAppendPages(to: url, settings) { newProgress, _ in
                Task { @MainActor in progress.wrappedValue = newProgress.fractionCompleted }
            }
            self.showNextPageDialog = true
        } catch {
            if !Task.isCancelled {
                ErrorHandler.shared.handle(error, while: "scanning document")
            }
        }
    }

    func discardPendingScan() {
        self.lastSavedFileURL = nil
        self.lastSettings = nil
    }
}

extension View {
    /// Presents the "scan more pages?" confirmation dialog used after a scan that could still be appended to.
    func scanMorePagesDialog(isPresented: Binding<Bool>, onAppend: @escaping () -> Void, onDone: @escaping () -> Void) -> some View {
        self
            .confirmationDialog("Scan more pages?", isPresented: isPresented) {
                Button("Yes (put the next page in the scanner before tapping)") {
                    onAppend()
                }
                Button("No (save scan)") {
                    onDone()
                }
            }
    }
}
