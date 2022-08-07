//
//  SelectSettings.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 03.08.22.
//

import SwiftUI

struct SelectSettings: View {
    
    //let capabilities = esclScanner(ip: "192.168.27.74").getCapabilities(uri: "https://192.168.27.74/eSCL/ScannerCapabilities")
    let capabilities: Scanner
    let queue = DispatchQueue(label: "scanqueue", qos: .userInitiated)
    let printer: PrinterRepresentation
    
    @State var selectedSource: String
    @State var selectedColorMode: String
    @State var selectedResolution: String
    @State var selectedFormat: String
    @State var selectedIntent: String
    @State var showSuccess: Bool = false
    @State var showError: Bool = false
    
    @Binding var scanning: Bool
    
    init(printer: PrinterRepresentation, scanning: Binding<Bool>) {
        self.capabilities = esclScanner(ip: printer.hostname).getCapabilities(uri: "https://"+printer.hostname+"/"+printer.root+"/ScannerCapabilities")
        self.selectedSource = capabilities.sourceCapabilities.keys.first ?? "Error"
        let temp = capabilities.sourceCapabilities.keys.first ?? "Error"
        self.selectedColorMode = capabilities.sourceCapabilities[temp]?.colorModes.first ?? "Error"
        //self.selectedColorMode = capabilities.colorModes.first ?? "Error"
        //self.selectedResolution = capabilities.discreteResolutions.first ?? "Error"
        self.selectedResolution = capabilities.sourceCapabilities[temp]?.discreteResolutions.first ?? "Error"
        //self.selectedFormat = capabilities.documentFormats.first ?? "Error"
        self.selectedFormat = capabilities.sourceCapabilities[temp]?.documentFormats.first ?? "Error"
        self.selectedIntent = capabilities.sourceCapabilities[temp]?.supportedIntents.first ?? "Error"
        self.printer = printer
        
        self._scanning = scanning
    }
    
    @Sendable private func delayText() async {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                showSuccess = false
                showError = false
            }
        }
    
    var body: some View {
        
        if showSuccess {
            Text("Scan saved!")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(Color.white)
                .task(delayText)
                .transition(.move(edge: .top))
        }
        if showError {
            Text("Encountered an error while scanning.")
                .multilineTextAlignment(.center)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(Color.white)
                .task(delayText)
                .transition(.move(edge: .top))
        }
        
        NavigationView {
            ZStack {
                VStack {
                    VStack {
                        Text("Sources:")
                        Picker("Please choose a source", selection: $selectedSource) {
                            ForEach(Array(capabilities.sourceCapabilities.keys), id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    //Spacer()
                    VStack {
                        Text("Colormodes:")
                        Picker("Please choose a colormode", selection: $selectedColorMode) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.colorModes ?? [], id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    //Spacer()
                    VStack {
                        Text("Resolutions:")
                        Picker("Please choose a resolution", selection: $selectedResolution) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.discreteResolutions ?? [], id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    //Spacer()
                    VStack {
                        Text("Formats:")
                        Picker("Please choose a format", selection: $selectedFormat) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.documentFormats ?? [], id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    VStack {
                        Text("Intents:")
                        Picker("Please choose an intent", selection: $selectedIntent) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.supportedIntents ?? [], id: \.self) {
                                Text($0)
                            }
                        }
                    }
                    //Spacer()
                    Button("Start scan!") {
                        scanning = true
                        queue.async {
                            let path = esclScanner(ip: printer.hostname).sendPostRequest(uri: "/\(printer.root)/ScanJobs", resolution: selectedResolution, colorMode: selectedColorMode, format: selectedFormat, version: capabilities.version, source: selectedSource, intent: selectedIntent)
                            print("scan finished! File saved at:")
                            print(path)
                            scanning = false
                            if path != nil {
                                withAnimation {
                                    showSuccess = true
                                }
                            } else {
                                withAnimation {
                                    showError = true
                                }
                            }
                        }
                        print("scan initiated")
                    }
                }
                if scanning {
                    LoadingOverlay()
                }
            }
        }
        .disabled(scanning)
        .navigationTitle(capabilities.makeAndModel)
        .navigationBarTitleDisplayMode(.inline)
    }
}
