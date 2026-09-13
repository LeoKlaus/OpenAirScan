//
//  DocumentPreview.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 24.01.25.
//

import SwiftUI
import UniformTypeIdentifiers
import EasyErrorHandling

/// This view displays a single document from a storage url. It is not relevant for the eSCL implementation.
struct DocumentPreview: View {
    
    @State private var data: Data?
    let type: UTType
    let docUrl: URL
    @State var showShareSheet: Bool = false
    
    init(docUrl: URL) {
        self.type = UTType(filenameExtension: docUrl.pathExtension) ?? .pdf
        self.docUrl = docUrl
    }
    
    @MainActor
    func loadDocument() {
        do {
            self.data = try Data(contentsOf: docUrl)
        } catch {
            ErrorHandler.shared.handle(error, while: "loading file")
        }
    }
    
    var body: some View {
            VStack {
                if let data {
                    if type == .pdf {
                        PDFKitRepresentedView(data)
                    } else {
                        Image(uiImage: UIImage(data: data) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    ProgressView()
                        .task {
                            self.loadDocument()
                        }
                }
            }.toolbar {
                ShareLink(item: docUrl)
            }
    }
}
