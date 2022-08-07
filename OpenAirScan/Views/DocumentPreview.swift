//
//  DocumentPreview.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 06.08.22.
//

import SwiftUI

/// This view displays a single document from a storage url. It is not relevant for the eSCL implementation.
struct DocumentPreview: View {
    
    let data: Data
    let type: String
    let docUrl: URL
    @State var showShareSheet: Bool = false
    
    init(docUrl: URL) {
        do {
            self.data = try Data(contentsOf: docUrl)
        } catch {
            print(error)
            self.data = Data()
        }
        if docUrl.pathExtension == "pdf" {
            self.type = "pdf"
        } else {
            self.type = "jpg"
        }
        self.docUrl = docUrl
    }
    
    var body: some View {
            VStack {
                if type == "pdf" {
                    PDFKitRepresentedView(data)
                } else {
                    Image(uiImage: UIImage(data: data) ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        
                }
            }.toolbar {
                Button (action: {
                    showShareSheet.toggle()
                }){
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .sheet(isPresented: $showShareSheet, content: {
                ActivityViewHandler(itemsToShare: [self.docUrl])
            })
    }
}
