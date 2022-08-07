//
//  StatusParser.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 07.08.22.
//

import Foundation

/**
 A custom XMLParser with support for the structure generated by a scanner.
 */
class StatusParser: XMLParser {
    // Public property to hold the result
    var status: String = ""
    
    private var textBuffer: String = ""
    override init(data: Data) {
        super.init(data: data)
        self.delegate = self
    }
}

/**
 The actual parser
 */
extension StatusParser: XMLParserDelegate {
    // Called when opening tag (`<elementName>`) is found
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "pwg:State":
            textBuffer = ""
        default:
            //print("Ignoring \(elementName)")
            break
        }
    }
    
    // Called when closing tag (`</elementName>`) is found
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "pwg:State":
            self.status = textBuffer
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