//
//  DocumentBrowser.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 06.08.22.
//  Licensed under the MIT License
//

import SwiftUI
import os

/// This view displays all documents stored in storage. It is not relevant for the eSCL implementation.
struct DocumentBrowser: View {
    
    // List of documents on disk
    @State var documents: [URL]
    
    private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: DocumentBrowser.self)
        )
    
    init() {
        self.documents = []
    }
    
    // Reload file list from storage
    func refresh() {
        do {
            let documentDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.documents = try FileManager.default.contentsOfDirectory(
                    at: documentDirectory,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
            )
            if documents != nil {
                documents = documents.sorted { $0.path > $1.path }
            }
        } catch {
            DocumentBrowser.logger.error("DocumentBrowser: Encountered error while getting documents: \(error, privacy: .public)")
        }
    }
    
    // Delete a file from storage
    func deleteFile(at offsets: IndexSet) {
        do {
            try FileManager.default.removeItem(at: documents[offsets.first!])
        } catch let error as NSError {
            DocumentBrowser.logger.error("DocumentBrowser: Error: \(error.domain, privacy: .public)")
        }
        self.documents.remove(at: offsets.first!)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    if self.documents.count == 0 {
                        Text("There are no scans yet.")
                    }
                    ForEach(self.documents, id: \.self) { document in
                        NavigationLink(document.lastPathComponent, destination: {
                            DocumentPreview(docUrl: document)
                        })
                    }.onDelete(perform: deleteFile)
                }
                .refreshable {
                    self.refresh()
                }
            }
                .navigationTitle("Documents")
                .navigationBarTitleDisplayMode(.inline)
            if documents.count > 0, let document = documents.first {
                DocumentPreview(docUrl: document)
            } else {
                Text("Scan a document first")
            }
        }
        .onAppear {
            self.refresh()
        }
    }
}

struct DocumentBrowser_Previews: PreviewProvider {
    static var previews: some View {
        DocumentBrowser()
    }
}
