//
//  ScannerListItem.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 04.08.22.
//  Licensed under the MIT License
//

import SwiftUI
import class SwiftESCL.ScannerRepresentation

/// View for a single scanner item in a list
struct ScannerListItem: View {
    
    let scanners: ScannerRepresentation
    
    var body: some View {
        HStack {
            AsyncImage(
                url: scanners.iconUrl,
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
                Text(scanners.model ?? "Unknown Model")
                    .font(.headline)
                Text(scanners.location ?? "Unknown Location")
            }
        }
    }
}
