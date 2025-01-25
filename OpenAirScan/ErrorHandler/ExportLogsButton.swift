//
//  ExportLogsButton.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import SwiftUI
import OSLog

struct ExportLogsButton: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    
    @State private var isCollectingLogs: Bool = false
    
    @State private var entries: [String] = []
    
    @State private var showExport: Bool = false
    
    private func exportLogs() {
        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let date = Date.now.addingTimeInterval(-24 * 3600)
            let position = store.position(date: date)
            
            entries = try store
                .getEntries(at: position)
                .compactMap { $0 as? OSLogEntryLog }
                .filter { $0.subsystem == Bundle.main.bundleIdentifier! }
                .map { "[\($0.date.formatted())] [\($0.category)] \($0.composedMessage)" }
        } catch {
            errorHandler.handle(error, while: "exporting logs")
        }
    }
    
    var body: some View {
        Button {
            DispatchQueue.global(qos: .userInitiated).async {
                isCollectingLogs = true
                exportLogs()
                isCollectingLogs = false
                showExport = true
            }
        } label: {
            if isCollectingLogs {
                ProgressView()
            } else {
                Label("Export Debug Logs", systemImage: "doc.text.fill")
            }
        }
        .sheet(isPresented: $showExport) {
            LogDisplay(entries: entries)
        }
    }
}

#Preview {
    ExportLogsButton()
}
