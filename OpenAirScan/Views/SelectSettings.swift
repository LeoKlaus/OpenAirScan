//
//  SelectSettings.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 03.08.22.
//  Licensed under the MIT License
//

import SwiftUI
import PDFKit
import struct SwiftESCL.Scanner
import class SwiftESCL.esclScanner

/// This view allows a user to select settings for the scan. It is not relevant for the eSCL implementation but can give insights on how to form a request.
struct SelectSettings: View {
    
    //let scannerRep: ScannerRepresentation
    let capabilities: Scanner
    let queue = DispatchQueue(label: "scanqueue", qos: .userInitiated)
    let scanner: esclScanner
    
    // State variables for user selections
    @State var selectedSource: String
    @State var selectedColorMode: String
    @State var selectedResolution: Int
    @State var selectedFileFormat: String
    @State var selectedPaperFormat: String
    @State var paperHeight: Int
    @State var paperWidth: Int
    @State var xOffset: Int
    @State var yOffset: Int
    // State variables for messages
    @State var showMessage: Bool = false
    @State var responseCode: Int = 0
    // This is used to block UI interaction while scanning
    @Binding var scanning: Bool
    @State var showNextPageDialog: Bool = false
    @State var multiPageScanFirstPage: PDFDocument = PDFDocument()
    // These are used to make the selections easier to understand
    // There's probably a much better way to do this but I won't spend too much time on this
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
    
    init(scanner: esclScanner, scanning: Binding<Bool>) {
        self.scanner = scanner
        self.capabilities = self.scanner.scanner
        self._scanning = scanning
        self.selectedSource = capabilities.sourceCapabilities.keys.first ?? "Error fetching sources"
        let temp = capabilities.sourceCapabilities.keys.first ?? "Error"
        self.selectedColorMode = capabilities.sourceCapabilities[temp]?.colorModes.first ?? "Error fetching color modes"
        self.selectedResolution = capabilities.sourceCapabilities[temp]?.supportedResolutions.first ?? 0
        self.selectedFileFormat = capabilities.sourceCapabilities[temp]?.documentFormats.first ?? "Error fetching formats"
        self.selectedPaperFormat = "DIN A4"
        self.paperWidth = 2480
        self.paperHeight = 3508
        self.xOffset = 0
        self.yOffset = 0
    }
    
    // This is only used to delay the dismissal of messages
    @Sendable private func delayText() async {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            withAnimation {
                showMessage = false
            }
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
                            ForEach(Array(capabilities.sourceCapabilities.keys), id: \.self) {
                                Text(humanReadableSource[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    HStack {
                        Text("Colormode:")
                        Spacer()
                        Picker("Please choose a colormode", selection: $selectedColorMode) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.colorModes ?? [], id: \.self) {
                                Text(humanReadableColormode[$0.lowercased()] ?? $0)
                            }
                        }
                    }.padding(.horizontal)
                    HStack {
                        Text("Resolution (DPI):")
                        Spacer()
                        Picker("Please choose a resolution", selection: $selectedResolution) {
                            ForEach(capabilities.sourceCapabilities[selectedSource]?.supportedResolutions ?? [], id: \.self) {
                                Text(String($0))
                            }
                        }
                    }.padding(.horizontal)
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
                        } // This is a bit hacky
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
                        
                        HStack {
                            Text("X-Offset:")
                            TextField("custom x offset", value: $xOffset, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                            Text("Y-Offset:")
                            TextField("custom y offset", value: $yOffset, formatter: NumberFormatter())
                                .keyboardType(.numberPad)
                        }.padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Button("Start scan!") {
                        scanning = true
                        queue.async {
                            if selectedFileFormat != "application/pdf" {
                                (_, self.responseCode) = self.scanner.scanDocumentAndSaveFile(resolution: selectedResolution, colorMode: selectedColorMode, format: selectedFileFormat, source: selectedSource, width: paperWidth, height: paperHeight, XOffset: xOffset, YOffset: yOffset)
                                
                                scanning = false
                                showMessage = true
                            }
                            else {
                                var pdfData: Data
                                (pdfData, self.responseCode) = self.scanner.scanDocument(resolution: selectedResolution, colorMode: selectedColorMode, format: selectedFileFormat, source: selectedSource, width: paperWidth, height: paperHeight, XOffset: xOffset, YOffset: yOffset)
                                
                                scanning = false
                                if self.responseCode != 200 {
                                    showMessage = true
                                } else {
                                    self.multiPageScanFirstPage = PDFDocument(data: pdfData)!
                                    showNextPageDialog = true
                                }
                            }
                        }
                    }.padding()
                        .foregroundColor(.white)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                        .confirmationDialog("Scan more pages?", isPresented: $showNextPageDialog) {
                            Button("Yes (put the next page in the scanner before tapping)") {
                                scanning = true
                                queue.async {
                                    var nextPageData: Data
                                    (nextPageData, self.responseCode) = self.scanner.scanDocument(resolution: selectedResolution, colorMode: selectedColorMode, format: selectedFileFormat, source: selectedSource, width: paperWidth, height: paperHeight)
                                    
                                    scanning = false
                                    if self.responseCode != 200 {
                                        showMessage = true
                                    } else {
                                        self.multiPageScanFirstPage.addPages(from: PDFDocument(data: nextPageData)!)
                                        showNextPageDialog = true
                                    }
                                }
                            }
                            Button("No (Save Scan)") {
                                var path: URL
                                
                                let fileExtension = ".pdf"

                                // This is just used for determinining a file name
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "YY-MM-dd-HH-mm-ss"
                                let filename = "scan-" + dateFormatter.string(from: Date()) + fileExtension
                                
                                path = FileManager.default.urls(for: .documentDirectory,
                                                                        in: .userDomainMask)[0].appendingPathComponent(filename)
                                self.multiPageScanFirstPage.write(to: path)
                                self.multiPageScanFirstPage = PDFDocument()
                                self.showMessage = true
                            }
                            Button("Cancel", role: .cancel) { self.multiPageScanFirstPage = PDFDocument() }
                        } message: {
                            Text("Scan another page of this document?")
                        }
                }
                .frame(maxWidth: 400)
                if scanning {
                    LoadingOverlay()
                }
            
        }
        .disabled(scanning)
        .navigationTitle(capabilities.makeAndModel)
        .navigationBarTitleDisplayMode(.inline)
    }
}
