//
//  DiscoverDevices.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 03.08.22.
//  Licensed under the MIT License
//

import SwiftUI
import Network
import class SwiftESCL.Browser
import class SwiftESCL.ScannerRepresentation
import class SwiftESCL.esclScanner

/// This view displays a list of all discovered devices. 
struct DiscoverDevices: View {
    
    @State var scannerDict: [String: ScannerRepresentation] = [:]
    @State var loadingTooLong: Bool = false
    
    @State var customHostname: String = ""
    @State var customRoot: String = "eSCL"
    let browser = Browser()
    
    private func delayText() async {
        try? await Task.sleep(nanoseconds: 7_500_000_000)
        loadingTooLong = true
        if scannerDict.count == 0 {
            print("loading took too long, displaying help text")
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if scannerDict.count == 0 {
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
                                    self.scannerDict[customHostname] = ScannerRepresentation(hostname: customHostname, root: customRoot)
                                }
                            }.padding()
                                .frame(maxWidth: 600)
                        }
                    } else {
                        ProgressView()
                    }
                } else {
                    List {
                        ForEach(Array(scannerDict.values), id: \.hostname) { scanner in
                            //NavigationLink(destination: SelectSettings(scanner: esclScanner(ip: scanner.hostname, root: scanner.root), scanning: $scanning)) {
                            //    ScannerListItem(scanners: scanner)
                            //}
                            NavigationLink(destination: QuickScan(scanner: esclScanner(ip: scanner.hostname, root: scanner.root))) {
                                ScannerListItem(scanners: scanner)
                            }
                        }
                    }
                    .frame(maxWidth: 600)
                }
            }
            .onAppear(perform: {
                browser.setDevices(scanners: $scannerDict)
                browser.start()
                Task {
                    await delayText()
                }
            })
            .navigationTitle("Scanners")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

