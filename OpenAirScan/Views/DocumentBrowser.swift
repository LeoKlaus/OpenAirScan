//
//  DocumentBrowser.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 06.08.22.
//  Licensed under the MIT License
//

import SwiftUI

/// This view displays all documents stored in storage. It is not relevant for the eSCL implementation.
struct DocumentBrowser: View {
    
    // List of documents on disk
    @State var documents: [URL]
    
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
        } catch {
            print(error)
        }
    }
    
    // Delete a file from storage
    func deleteFile(at offsets: IndexSet) {
        do {
            try FileManager.default.removeItem(at: documents[offsets.first!])
        } catch let error as NSError {
            print("Error: \(error.domain)")
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
                .onAppear {
                    self.refresh()
                }
                .refreshable {
                    self.refresh()
                }
            }
                .navigationTitle("Documents")
                .navigationBarTitleDisplayMode(.inline)
            if documents.count > 0, let document = documents[0] {
                DocumentPreview(docUrl: document)
            } else {
                Text("Scan a document first")
            }
        }
    }
}

struct DocumentBrowser_Previews: PreviewProvider {
    static var previews: some View {
        DocumentBrowser()
    }
}
