//
//  ContentView.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 20.01.25.
//

import SwiftUI
import SwiftESCL

enum ContentViewTab {
    case scanning
    case documents
}

struct ContentView: View {
    
    @ObservedObject private var tabStateHandler = TabStateHandler()
    @ObservedObject var scannerBrowser = ScannerBrowser()
    @StateObject private var presetStore = PresetStore()
    
    var body: some View {
        TabView(selection: $tabStateHandler.currentTab) {
            ScannerBrowserView()
                .environmentObject(scannerBrowser)
                .tag(ContentViewTab.scanning)
                .tabItem {
                    Label("Scan", systemImage: "scanner")
                }
            DocumentBrowser()
                .tag(ContentViewTab.documents)
                .tabItem{
                    Label("Documents", systemImage: "doc.on.doc")
                }
        }
        .environmentObject(tabStateHandler)
        .environmentObject(presetStore)
    }
}

#Preview {
    ContentView()
}
