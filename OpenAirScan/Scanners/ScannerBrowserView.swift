//
//  ScannerBrowserView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 24.01.25.
//

import SwiftUI
import SwiftESCL

struct ScannerBrowserView: View {
    
    @EnvironmentObject var scannerBrowser: ScannerBrowser
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.scannerBrowser.discovered) { scannerRep in
                    NavigationLink(destination: ScannerDetailView(scannerRep)) {
                        ScannerListItem(scanner: scannerRep)
                    }
                }
            }
            .navigationTitle("Scanners")
            .task {
                self.scannerBrowser.startDiscovery()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ExportLogsButton()
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    ScannerBrowserView()
        .environmentObject(ScannerBrowser.mock)
}
#endif
