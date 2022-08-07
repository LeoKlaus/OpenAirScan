//
//  SelectSettings.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 03.08.22.
//

import SwiftUI

struct SelectSettings: View {
    
    let printer: PrinterRepresentation
    let capabilities: Scanner
    let queue = DispatchQueue(label: "scanqueue", qos: .userInitiated)
    
    
    @State var selectedSource: String
    @State var selectedColorMode: String
    @State var selectedResolution: String
    @State var selectedFileFormat: String
    @State var selectedPaperFormat: String
    @State var paperHeight: Int
    @State var paperWidth: Int
    @State var selectedIntent: String
    @State var showSuccess: Bool = false
    @State var showError: Bool = false
    
    @Binding var scanning: Bool
    
    let humanReadableSource: [String:String] = [
        "platen":   "Flatbed",
        "adf":      "Document Feeder",
        "camera":   "Camera"
    ]
    let humanReadableColormode: [String:String] = [
        "blackandwhite1":   "Black and White",
        "grayscale8":       "Grayscale",
        "rgb24":            "Color"
    ]
    let humanReadableFormat: [String:String] = [
        "application/pdf":  "PDF",
        "image/jpg":        "JPG Image",
        "image/jpeg":       "JPEG Image",
        "image/png":        "PNG Image"
    ]
    let humanReadableIntent: [String:String] = [
        "textandgraphic":   "Text and Graphics"
    ]
    
    let paperSizes = ["DIN A4", "DIN A5", "DIN A6", "Letter", "Legal", "Custom"]
    
    let humanReadablePaperSizes: [String:[Int]] = [
        "DIN A4": [2480, 3508],
        "DIN A5": [1748, 2480],
        "DIN A6": [1240, 1748],
        "Letter": [3295, 2551],
        "Legal": [4205, 2551],
        "Custom": [1000, 2000]
    ]
    
    init(printer: PrinterRepresentation, scanning: Binding<Bool>) {
        self.printer = printer
        self.capabilities = esclScanner(ip: printer.hostname).getCapabilities(uri: "https://"+printer.hostname+"/"+printer.root+"/ScannerCapabilities")
        self._scanning = scanning
        self.selectedSource = capabilities.sourceCapabilities.keys.first ?? "Error fetching sources"
        let temp = capabilities.sourceCapabilities.keys.first ?? "Error"
        self.selectedColorMode = capabilities.sourceCapabilities[temp]?.colorModes.first ?? "Error fetching color modes"
        self.selectedResolution = capabilities.sourceCapabilities[temp]?.discreteResolutions.first ?? "Error fetching resolutions"
        self.selectedFileFormat = capabilities.sourceCapabilities[temp]?.documentFormats.first ?? "Error fetching formats"
        self.selectedIntent = capabilities.sourceCapabilities[temp]?.supportedIntents.first ?? "Error fetching intents"
        self.selectedPaperFormat = "DIN A4"
        self.paperWidth = 2480
        self.paperHeight = 3508
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
                    HStack {
                        Text("Source:")
                        Spacer()
                        Picker("Please choose a source", selection: $selectedSource) {
                            ForEach(Array(capabilities.sourceCapabilities.keys), id: \.self) {
                                Text(humanReadableSource[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    //Spacer()
                    HStack {
                        Text("Colormode:")
                        Spacer()
                        Picker("Please choose a colormode", selection: $selectedColorMode) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.colorModes ?? [], id: \.self) {
                                Text(humanReadableColormode[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    //Spacer()
                    HStack {
                        Text("Resolution (DPI):")
                        Spacer()
                        Picker("Please choose a resolution", selection: $selectedResolution) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.discreteResolutions ?? [], id: \.self) {
                                Text($0)
                            }
                        }
                    }.padding(.horizontal)
                    //Spacer()
                    HStack {
                        Text("File format:")
                        Spacer()
                        Picker("Please choose a format", selection: $selectedFileFormat) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.documentFormats ?? [], id: \.self) {
                                Text(humanReadableFormat[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    HStack {
                        Text("Paper size:")
                        Spacer()
                        Picker("Please choose a paper size", selection: $selectedPaperFormat) {
                            ForEach(paperSizes, id: \.self) {
                                Text($0)
                            }
                        }
                        .onChange(of: selectedPaperFormat) { tag in
                            self.paperWidth = humanReadablePaperSizes[selectedPaperFormat]![0]
                            self.paperHeight = humanReadablePaperSizes[selectedPaperFormat]![1]
                        }
                    }.padding(.horizontal)
                    if selectedPaperFormat == "Custom" {
                        HStack {
                            Text("Width:")
                            TextField("custom width", value: $paperWidth, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                            Text("Height:")
                            TextField("custom height", value: $paperHeight, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }.padding(.horizontal)
                    }
                    HStack {
                        Text("Intent:")
                        Spacer()
                        Picker("Please choose an intent", selection: $selectedIntent) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.supportedIntents ?? [], id: \.self) {
                                Text(humanReadableIntent[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    
                    //if lastScanURL == nil {
                        Spacer()
                    //} else {
                    //    DocumentPreview(docUrl: lastScanURL!)
                    //}
                    
                    Button("Start scan!") {
                        scanning = true
                        queue.async {
                            let path = esclScanner(ip: printer.hostname).sendPostRequest(uri: "/\(printer.root)/ScanJobs", resolution: selectedResolution, colorMode: selectedColorMode, format: selectedFileFormat, version: capabilities.version, source: selectedSource, width: paperWidth, height: paperHeight, intent: selectedIntent)
                            print("scan finished! File saved at:")
                            print(path)
                            //self.lastScanURL = path
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
                    }.padding()
                        .foregroundColor(.white)
                        .background(.blue)
                        .clipShape(Capsule())
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
