//
//  PDFDocument.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 30.08.22.
//

import Foundation
import PDFKit

extension PDFDocument {
    
        func addPages(from document: PDFDocument) {
            let pageCountAddition = document.pageCount
    
            for pageIndex in 0..<pageCountAddition {
                guard let addPage = document.page(at: pageIndex) else {
                    break
                }
    
                self.insert(addPage, at: self.pageCount) // unfortunately this is very very confusing. The index is the page *after* the insertion. Every normal programmer would assume insert at self.pageCount-1
            }
        }
    
    }
