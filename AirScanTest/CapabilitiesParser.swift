//
//  CapabilitiesParser.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 03.08.22.
//

import Foundation

struct Scanner {
    var version: String = ""
    var makeAndModel: String = ""
    var sourceCapabilities: [String: Capabilities] = [:]
}

struct Capabilities {
    var minWidth: String = ""
    var maxWidth: String = ""
    var minHeight: String = ""
    var maxHeight: String = ""
    var colorModes: [String] = []
    var documentFormats: [String] = []
    var discreteResolutions: [String] = []
    var supportedIntents: [String] = []
}

class ArticlesParser: XMLParser {
    // Public property to hold the result
    var scanner: Scanner = Scanner()
    var capabilities = Capabilities()
    
    private var textBuffer: String = ""
    override init(data: Data) {
        super.init(data: data)
        self.delegate = self
    }
}
extension ArticlesParser: XMLParserDelegate {
    // Called when opening tag (`<elementName>`) is found
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "pwg:Version":
            textBuffer = ""
        case "pwg:MakeAndModel":
            textBuffer = ""
        case "scan:Platen":
            self.capabilities = Capabilities()
        case "scan:Adf":
            self.capabilities = Capabilities()
        case "scan:Camera":
            self.capabilities = Capabilities()
        case "scan:platen":
            self.capabilities = Capabilities()
        case "scan:adf":
            self.capabilities = Capabilities()
        case "scan:camera":
            self.capabilities = Capabilities()
        case "scan:MinWidth":
            textBuffer = ""
        case "scan:MaxWidth":
            textBuffer = ""
        case "scan:MinHeight":
            textBuffer = ""
        case "scan:MaxHeight":
            textBuffer = ""
        case "scan:ColorMode":
            textBuffer = ""
        case "pwg:DocumentFormat":
            textBuffer = ""
        case "scan:XResolution":
            textBuffer = ""
        case "scan:Intent":
            textBuffer = ""
        default:
            //print("Ignoring \(elementName)")
            break
        }
    }
    
    // Called when closing tag (`</elementName>`) is found
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "pwg:Version":
            self.scanner.version = textBuffer
        case "pwg:MakeAndModel":
            self.scanner.makeAndModel = textBuffer
        case "scan:Platen":
            self.scanner.sourceCapabilities["Platen"] = self.capabilities
        case "scan:platen":
            self.scanner.sourceCapabilities["Platen"] = self.capabilities
        case "scan:Adf":
            self.scanner.sourceCapabilities["Adf"] = self.capabilities
        case "scan:adf":
            self.scanner.sourceCapabilities["Adf"] = self.capabilities
        case "scan:Camera":
            self.scanner.sourceCapabilities["Camera"] = self.capabilities
        case "scan:camera":
            self.scanner.sourceCapabilities["Camera"] = self.capabilities
        case "scan:MinWidth":
            self.capabilities.minWidth = textBuffer
        case "scan:MaxWidth":
            self.capabilities.maxWidth = textBuffer
        case "scan:MinHeight":
            self.capabilities.minHeight = textBuffer
        case "scan:MaxHeight":
            self.capabilities.maxHeight = textBuffer
        case "scan:ColorMode":
            self.capabilities.colorModes.append(textBuffer)
        case "pwg:DocumentFormat":
            self.capabilities.documentFormats.append(textBuffer)
        case "scan:XResolution":
            self.capabilities.discreteResolutions.append(textBuffer)
        case "scan:Intent":
            self.capabilities.supportedIntents.append(textBuffer)
        default:
            //print("Ignoring \(elementName)")
            break
        }
    }
    
    // Called when a character sequence is found
    // This may be called multiple times in a single element
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        textBuffer += string
    }
    
    // Called when a CDATA block is found
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard let string = String(data: CDATABlock, encoding: .utf8) else {
            print("CDATA contains non-textual data, ignored")
            return
        }
        textBuffer += string
    }
    
    // For debugging
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
        print("on:", parser.lineNumber, "at:", parser.columnNumber)
    }
}
