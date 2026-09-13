//
//  ScannerBrowserView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 24.01.25.
//

import SwiftUI
import SwiftESCL
import EasyErrorHandling

struct ScannerBrowserView: View {
    
    @EnvironmentObject var scannerBrowser: ScannerBrowser
    
    @State private var hasSearched: Bool = false
    
    private func delayHint() async {
        try? await Task.sleep(for: .seconds(10))
        withAnimation {
            self.hasSearched = true
        }
    }
    
    private func switchToHttp() {
        withAnimation {
            self.hasSearched = false
        }
        self.scannerBrowser.switchEncryption(usePlainText: true)
        self.scannerBrowser.startDiscovery()
        Task {
            await self.delayHint()
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(self.scannerBrowser.discovered) { scannerRep in
                    NavigationLink(destination: ScannerDetailView(scannerRep)) {
                        ScannerListItem(scanner: scannerRep)
                    }
                }
                
                if self.scannerBrowser.discovered.isEmpty {
                    if self.hasSearched {
                        ContentUnavailableView {
                            Label("No scanners found", systemImage: "scanner")
                        } description: {
                            Text("OpenAirScan didn't find any compatible scanners on your network.")
                                .font(.footnote)
                                .padding(.top, 5)
                        }
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        Button("Retry with plain HTTP", systemImage: "lock.slash", action: self.switchToHttp)
                    } else {
                        ProgressView("Searching for scanners...")
                            .listRowBackground(EmptyView())
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Scanners")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                self.scannerBrowser.startDiscovery()
                await self.delayHint()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    ExportLogsButton("Export logs")
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
