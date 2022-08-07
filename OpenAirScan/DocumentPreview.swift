//
//  DocumentPreview.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 06.08.22.
//

import SwiftUI

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
                // For some reason inexplicable to me, this leads to the app crashing when opening the share sheet in the simulator with debugging connected. Opening the share sheet on a physical device works as expected, even with the debugger connected, so does opening it in the simulator when the debugger is not connected. I'm assuming this is a bug in xcode 14 and I won't put any effort into fixing this for now.
                // Confirmed its working in xcode 13.4 with its simulator
                ActivityViewHandler(itemsToShare: [self.docUrl])
            })
    }
}
