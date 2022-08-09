//
//  PDFKitRepresentedView.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 04.06.22.
//  Licensed under the MIT License
//

import PDFKit
import SwiftUI

/// This is used to make PDFView usable in SwiftUI
struct PDFKitRepresentedView: UIViewRepresentable {
    typealias UIViewType = PDFView

    let data: Data

    init(_ data: Data) {
        self.data = data
    }

    func makeUIView(context _: UIViewRepresentableContext<PDFKitRepresentedView>) -> UIViewType {
        // Create a PDFView and set its PDFDocument.
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
