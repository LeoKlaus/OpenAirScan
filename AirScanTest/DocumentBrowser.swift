//
//  DocumentBrowser.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 06.08.22.
//

import SwiftUI

struct DocumentBrowser: View {
    
    @State var documents: [URL]
    
    init() {
        self.documents = []
    }
    
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
        }
    }
}

struct DocumentBrowser_Previews: PreviewProvider {
    static var previews: some View {
        DocumentBrowser()
    }
}
