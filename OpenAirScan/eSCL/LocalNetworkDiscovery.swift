//
//  LocalNetworkDiscovery.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 14.07.22.
//  Licensed under the MIT License
//

import Foundation
import Network
import SwiftUI

/**
 An object storing the attributes of a single scanner.
 */
class ScannerRepresentation {
    var hostname: String
    var location: String?
    var model: String?
    var iconUrl: URL?
    var root: String
    
    /**
     This initialiser is only meant for manually adding devices if Bonjour doesn't work or isn't avaiable.
     - Parameter hostname: String containing the hostname/ip of the scanner.
     - Parameter root: The path to the eSCL root of the device. This should be  "eSCL" for most devices.
     */
    init(hostname: String, root: String) {
        self.hostname = hostname
        self.root = root
    }
    
    /**
     The main initialiser. This takes a TXT-Record from the Bonjour discovery and retrieves all necessary data.
     -  Parameter txtRecord: An NWTXTRecord returned by an eSCL-Compliant scanner.
     */
    init(txtRecord: NWTXTRecord) {
        let recordDict = txtRecord.dictionary
        self.hostname = URL(string: recordDict["adminurl"] ?? "")!.host!
        // Location
        if recordDict["note"] != nil {
            self.location = recordDict["note"]
        }
        // Make and model
        if recordDict["ty"] != nil {
            self.model = recordDict["ty"]
        }
        // URL to a small image of the device
        if recordDict["representation"] != nil {
            if recordDict["representation"]!.starts(with: "http") {
                // Because of the self signed certificate, the image has to be loaded via http to prevent certificate errors in AsyncImage
                self.iconUrl = URL(string: recordDict["representation"]!.replacingOccurrences(of: "https:", with: "http:"))
            }
            else {
                self.iconUrl = URL(string: "http://" + self.hostname + recordDict["representation"]!)
            }
        }
        // eSCL root of the device
        self.root = recordDict["rs"]!
    }
    
    /// Prints all stored information of the device
    func printScanner() {
        print("Host: \(self.hostname)")
        print("Location: \(self.location)")
        print("Model: \(self.model)")
        print("Icon: \(self.iconUrl)")
        print("Root: \(self.root)")
    }
}

/**
 Object that can handle Bonjour requests.
 */
class Browser {
    
    let browser: NWBrowser
    /// A dictionary in the format [hostname:ScannerRepresentation] of discovered devices.
    var scanners: Binding<[String:ScannerRepresentation]>?

    /**
     Create a new browser without a binding dictionary. Calling start() on this won't do anything.
     */
    init() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_uscan._tcp", domain: nil), using: parameters)
        self.scanners = nil
    }
    
    /**
     Method to pass a binding dictionary to the browser. This isn't done in the main init to prevent issues with initiation in other classes.
     - Parameter scanners: A binding dictionary in the format [hostname:ScannerRepresentation] of discovered devices.
     */
    func setDevices(scanners: Binding<[String:ScannerRepresentation]>) {
        self.scanners = scanners
    }

    /**
     Method to start discovery of devices via Bonjour.
     */
    func start() {
        browser.stateUpdateHandler = { newState in
            print("browser.stateUpdateHandler \(newState)")
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            results.forEach{ device in
                //print("Device metadata: \(device.metadata)")
                switch device.metadata {
                    
                case .bonjour(let record):
                    // Generate a ScannerRepresentation object containing all information the scanner provided.
                    let scanner = ScannerRepresentation(txtRecord: record)
                    self.scanners![scanner.hostname].wrappedValue = scanner
                    
                case .none:
                    print("Record: none")
                @unknown default:
                    print("Record: default")
                }
            }
        }
        browser.start(queue: .main)
    }
}
