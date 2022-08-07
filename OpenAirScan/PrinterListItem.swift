//
//  PrinterListItem.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 04.08.22.
//

import SwiftUI

struct PrinterListItem: View {
    
    let printer: PrinterRepresentation
    
    var body: some View {
        HStack {
            AsyncImage(
                url: printer.iconUrl,
                            content: { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                                     .frame(maxWidth: 64, maxHeight: 64)
                            },
                            placeholder: {
                                ProgressView()
                                    .frame(maxWidth: 64, maxHeight: 64)
                            }
                        )
            VStack {
                Text(printer.model ?? "Unknown Model")
                    .font(.headline)
                Text(printer.location ?? "Unknown Location")
            }
        }
    }
}
