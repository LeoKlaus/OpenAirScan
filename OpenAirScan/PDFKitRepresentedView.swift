//
// Created by Leo Wehrfritz on 04.06.22.
// Copyright (c) 2022 Leo Wehrfritz. All rights reserved.
//

import PDFKit
import SwiftUI

/**struct PDFKitRepresentedView: UIViewRepresentable {
    
    let data: Data

    init(_ data: Data) {
        self.data = data
    }
    
    init(documentId: Int, apiHandler: ApiHandler) {
        let (path, _) = apiHandler.get_document(id: documentId)
        // TODO: Load data from disk using path
        print(path)
        self.data = Data()
    }

    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
        // Create a `PDFView` and set its `PDFDocument`.
        let pdfView = PDFView()
        pdfView.document = PDFDocument(data: self.data)
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: nil)
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
        // Update the view.
    }
}*/

struct PDFKitRepresentedView: UIViewRepresentable {
    typealias UIViewType = PDFView

    let data: Data

    init(_ data: Data) {
        self.data = data
    }

    func makeUIView(context _: UIViewRepresentableContext<PDFKitRepresentedView>) -> UIViewType {
        // Create a `PDFView` and set its `PDFDocument`.
        let pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        pdfView.autoScales = true
        pdfView.displayDirection = .horizontal
        pdfView.document = PDFDocument(data: data)
        pdfView.usePageViewController(true)
        return pdfView
    }

    func updateUIView(_ pdfView: UIViewType, context _: UIViewRepresentableContext<PDFKitRepresentedView>) {
        //pdfView.document = PDFDocument(data: data)
    }
}
