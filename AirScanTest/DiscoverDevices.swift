//
//  DiscoverDevices.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 03.08.22.
//

import SwiftUI
import Network

struct DiscoverDevices: View {
    
    @State var printerDict: [String: PrinterRepresentation] = [:]
    @State var loadingTooLong: Bool = false
    
    @State var customHostname: String = ""
    @State var customRoot: String = "eSCL"
    
    @Binding var scanning: Bool
    
    private func delayText() async {
        // Delay of 7.5 seconds (1 second = 1_000_000_000 nanoseconds)
        try? await Task.sleep(nanoseconds: 7_500_000_000)
        loadingTooLong = true
        print("loading took too long, displaying help text")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if printerDict.count == 0 {
                    if loadingTooLong {
                        ScrollView {
                            Text("No devices found :(")
                                .font(.headline)
                            Text("We'll keep trying in the background.")
                            Spacer()
                            Text("Troubleshooting steps:")
                                .font(.headline)
                            Text("- Confirm the scanner is turned on and connected to the same network as your device.\n- Confirm your scanner supports eSCL (often referred to as AirScan).\n- Your scanner has to support Bonjour and it has to be enabled.\n- You have to allow this app to discover devices on your local network.")
                                .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                            Spacer()
                            VStack {
                                Text("You can also try to manually add your scanner:")
                                    .font(.headline)
                                Text("Hostname/IP:")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("Hostname:", text: $customHostname, prompt: Text("192.168.1.123"))
                                    .textContentType(.URL)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.roundedBorder)
                                Text("Root directory for eSCL. Don't change this unless you know you have to:")
                                TextField("eSCL Root:", text: $customRoot)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .textFieldStyle(.roundedBorder)
                                Button("Add custom scanner") {
                                    self.printerDict[customHostname] = PrinterRepresentation(hostname: customHostname, root: customRoot)
                                }
                            }.padding()
                        }
                    } else {
                        ProgressView()
                    }
                } else {
                    List {
                        ForEach(Array(printerDict.values), id: \.hostname) { printer in
                            NavigationLink(destination: SelectSettings(printer: printer, scanning: $scanning)) {
                                PrinterListItem(printer: printer)
                            }
                        }
                    }
                    .refreshable {
                        let browser = Browser(printers: $printerDict)
                        browser.start()
                    }
                }
            }
            .onAppear(perform: {
                let browser = Browser(printers: $printerDict)
                browser.start()
                Task {
                    await delayText()
                }
            })
            .navigationTitle("Scanners")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

