import Foundation
import Network
import SwiftUI

class PrinterRepresentation {
    var hostname: String
    var location: String?
    var model: String?
    var iconUrl: URL?
    var root: String
    
    init(hostname: String, root: String) {
        self.hostname = hostname
        self.root = root
    }
    
    init(txtRecord: NWTXTRecord) {
        let recordDict = txtRecord.dictionary
        self.hostname = URL(string: recordDict["adminurl"] ?? "")!.host() ?? ""
        
        if recordDict["note"] != nil {
            self.location = recordDict["note"]
        }
        if recordDict["ty"] != nil {
            self.model = recordDict["ty"]
        }
        if recordDict["representation"] != nil {
            if recordDict["representation"]!.starts(with: "http") {
                self.iconUrl = URL(string: recordDict["representation"]!.replacingOccurrences(of: "https:", with: "http:"))
            }
            else {
                self.iconUrl = URL(string: "http://" + self.hostname + recordDict["representation"]!)
            }
        }
        self.root = recordDict["rs"] ?? ""
    }
    
    func printPrinter() {
        print("Host: \(self.hostname)")
        print("Location: \(self.location)")
        print("Model: \(self.model)")
        print("Icon: \(self.iconUrl)")
        print("Root: \(self.root)")
    }
}

class Browser {

    let browser: NWBrowser
    var printers: Binding<[String:PrinterRepresentation]>

    init(printers: Binding<[String:PrinterRepresentation]>) {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_uscan._tcp", domain: nil), using: parameters)
        self.printers = printers
    }

    func start() {
        browser.stateUpdateHandler = { newState in
            print("browser.stateUpdateHandler \(newState)")
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            results.forEach{ device in
                //print("Device metadata: \(device.metadata)")
                switch device.metadata {
                    
                case .bonjour(let record):
                    print("Record: \(record.dictionary)")
                    //self.printers.append(PrinterRepresentation(txtRecord: record))
                    //self.printers.wrappedValue.append(PrinterRepresentation(txtRecord: record))
                    let printer = PrinterRepresentation(txtRecord: record)
                    self.printers[printer.hostname].wrappedValue = printer
                    
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
