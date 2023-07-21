//
//  LogDisplay.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 21.07.23.
//

import SwiftUI

struct LogDisplay: View {
    
    let entries: [String]
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(entries.joined(separator: "\n"))
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIPasteboard.general.string = entries.joined(separator: "\n")
                    } label: {
                        Label("Copy to clipboard", systemImage: "doc.on.doc.fill")
                    }
                }
            }
        }
    }
}

#Preview {
    LogDisplay(entries: ["A", "B", "C"])
}
