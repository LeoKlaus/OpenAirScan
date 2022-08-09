//
//  ContentView.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 14.07.22.
//  Licensed under the MIT License
//

import SwiftUI

struct ContentView: View {
    
    @State var scanning: Bool = false
    
    var body: some View {
        TabView {
            DiscoverDevices(scanning: $scanning).tabItem {
                Label("Scan", systemImage: "scanner")
            }
            DocumentBrowser().tabItem{
                Label("Documents", systemImage: "doc.on.doc")
            }
        }
        .disabled(scanning)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
