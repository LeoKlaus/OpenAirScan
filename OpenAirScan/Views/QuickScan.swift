//
//  QuickScan.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 12.08.22.
//

import SwiftUI
import class SwiftESCL.esclScanner

struct QuickScan: View {
    
    let scanner: esclScanner
    @State var scanning: Bool = false
    @State var selectedSource: String
    @State var customNavigationActive: Bool = false
    let queue = DispatchQueue(label: "scanqueue", qos: .userInitiated)
    
    let humanReadableSource: [String:String] = [
        "platen":   "Flatbed",
        "adf":      "Document Feeder",
        "camera":   "Camera"
    ]
    let humanReadableIntent: [String:String] = [
        "textandgraphic":   "Text and Graphics"
    ]
    
    init(scanner: esclScanner) {
        self.scanner = scanner
        self.selectedSource = scanner.scanner.sourceCapabilities.keys.first ?? "No sources found"
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Source:")
                    Spacer()
                    Picker("Please choose a source", selection: $selectedSource) {
                        ForEach(Array(scanner.scanner.sourceCapabilities.keys), id: \.self) {
                            Text(humanReadableSource[$0.lowercased()] ?? $0)
                        }
                    }
                }.padding(.horizontal)
                List {
                    ForEach(scanner.scanner.sourceCapabilities[selectedSource]?.supportedIntents ?? [], id: \.self) { intent in
                        Button(humanReadableIntent[intent.lowercased()] ?? intent) {
                            scanning = true
                            queue.async {
                                self.scanner.scanDocumentAndSaveFile(intent: intent)
                                scanning = false
                                //showMessage = true
                            }
                        }
                    }
                    NavigationLink(
                        "Custom Scan", destination: SelectSettings(scanner: scanner, scanning: $scanning)
                    )
                }
            }
        if scanning {
            LoadingOverlay()
        }
        }
        .disabled(scanning)
        .navigationTitle(scanner.scanner.makeAndModel)
        .navigationBarTitleDisplayMode(.inline)
    }
}
