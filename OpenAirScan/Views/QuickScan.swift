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
    // State variables for messages
    @State var showMessage: Bool = false
    @State var responseCode: Int = 0
    
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
    
    func generateMessage() -> String {
        if self.responseCode == 200 {
            return "Scan saved!"
        }
        else if self.responseCode == 408 {
            return "Scan failed: Timed out while waiting for the document"
        }
        else if self.responseCode == 409 {
            return "Scan failed: Malformed request!\nYou likely tried to mix parameters that can't be mixed."
        }
        else if self.responseCode == 503 {
            return "Scan failed: The scanner is busy!"
        }
        return "Encountered an unknown error! \(self.responseCode)"
    }
    
    // This is only used to delay the dismissal of messages
    @Sendable private func delayText() async {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            withAnimation {
                showMessage = false
            }
        }
    
    var body: some View {
        if showMessage {
            Text(self.generateMessage())
                .padding()
                .frame(maxWidth: .infinity)
                .background(self.responseCode == 200 ? Color.green : Color.red)
                .foregroundColor(Color.white)
                .task(delayText)
                .transition(.move(edge: .top))
        }
        
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
                                (_, self.responseCode) = self.scanner.scanDocumentAndSaveFile(source: selectedSource, intent: intent)
                                scanning = false
                                showMessage = true
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
