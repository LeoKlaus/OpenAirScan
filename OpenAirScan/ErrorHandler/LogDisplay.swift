//
//  LogDisplay.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import SwiftUI

struct LogDisplay: View {
    
    @Environment(\.dismiss) var dismiss
    
    let entries: [String]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(entries.joined(separator: "\n"))
            }
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Dismiss", systemImage: "xmark.circle")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
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
