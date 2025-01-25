//
//  DocumentBrowser.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 24.01.25.
//


import SwiftUI

/// This view displays all documents stored in storage. It is not relevant for the eSCL implementation.
struct DocumentBrowser: View {
    
    @EnvironmentObject var errorHandler: ErrorHandler
    
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
            
            documents = documents.sorted { $0.path > $1.path }
        } catch {
            errorHandler.handle(error, while: "fetching documents")
        }
    }
    
    // Delete a file from storage
    func deleteFile(at offsets: IndexSet) {
        do {
            try FileManager.default.removeItem(at: documents[offsets.first!])
        } catch  {
            errorHandler.handle(error, while: "deleting file")
        }
        self.documents.remove(at: offsets.first!)
    }
    
    var body: some View {
        NavigationSplitView {
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
        } detail: {
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
