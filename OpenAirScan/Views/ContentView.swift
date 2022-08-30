//
//  ContentView.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 14.07.22.
//  Licensed under the MIT License
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        TabView {
            DiscoverDevices().tabItem {
                Label("Scan", systemImage: "scanner")
            }
            DocumentBrowser().tabItem{
                Label("Documents", systemImage: "doc.on.doc")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
