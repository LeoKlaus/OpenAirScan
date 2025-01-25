//
//  ScannerListItem.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 20.01.25.
//

import SwiftUI
import SwiftESCL

struct ScannerListItem: View {
    
    let scanner: EsclScanner
    
    var body: some View {
        HStack {
            
            AsyncImage(url: scanner.iconUrl) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                Image(systemName: "scanner")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(scanner.model ?? "Unknown Model")
                    .bold()
                Text(scanner.location ?? "Unknown Location")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    
    if let scanner = try? EsclScanner(hostname: "test", root: "eSCL") {
        
        ScannerListItem(scanner: scanner)
    }
}
