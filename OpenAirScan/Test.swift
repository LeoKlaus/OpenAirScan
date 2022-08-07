//
//  Test.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 14.07.22.
//

import Foundation
import Combine

class esclScanner: NSObject, URLSessionDelegate {
    var ip: String
    var baseURI: String
    var responseURL = ""

    init(ip: String) {
        self.ip = ip
        self.baseURI = "https://\(ip)"
    }
    
    func getCapabilities(uri: String) -> Scanner {
        
        var capabilities = Scanner()
        
        var urlRequest = URLRequest(url: URL(string: uri)!)
        
        urlRequest.httpMethod = "GET"
        
        let configuration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.init())
        
        let sem = DispatchSemaphore.init(value: 0)
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            defer { sem.signal() }
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard(200 ... 299) ~= response.statusCode else {
                print("Statuscode should be 2xx but is \(response.statusCode)")
                //print("response = \(response)")
                return
            }
            
            //let parser = XMLParser(data: data)
            let parser = ArticlesParser(data: data)
            let success:Bool = parser.parse()
            if success {
                print("success")
                capabilities = parser.scanner
            } else {
                print("parse failure!")
            }
        }
        
        task.resume()
        sem.wait()
        return capabilities
    }
    
    func sendGetRequest(uri: String, format: String) -> (URL?, Int) {

        var urlRequest = URLRequest(url: URL(string: uri)!)
        
        let fileExtension = (format == "application/pdf") ? ".pdf" : ".jpeg"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY-MM-DD-HH-mm-ss"
        let filename = "scan-" + dateFormatter.string(from: Date.now) + fileExtension
        
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent(filename)
        var responseCode = 0
        urlRequest.httpMethod = "GET"
        
        let configuration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.init())
        
        let sem = DispatchSemaphore.init(value: 0)
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            defer { sem.signal() }
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            responseCode = response.statusCode
            guard(200 ... 299) ~= response.statusCode else {
                print("Statuscode should be 2xx but is \(response.statusCode)")
                //print("response = \(response)")
                return
            }
            
            try? data.write(to: path)
        }
        
        task.resume()
        sem.wait()
        return (path, responseCode)
    }
    
    func sendPostRequest(uri: String, resolution: String = "300", colorMode: String = "RGB24", format: String = "application/pdf", version: String = "2.5", source: String = "Platen", width: String = "2550", height: String = "3510", XOffset: String = "0", YOffset: String = "0", intent: String = "Document") -> URL? {
        print("sendControllerPostRequest")
        var urlRequest = URLRequest(url: URL(string: self.baseURI+uri)!)
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        
        var fuckYouMopriaForMakingThisSoComplicated: String
        if source == "Adf" || source == "adf" {
            fuckYouMopriaForMakingThisSoComplicated = "Feeder"
        }
        else if source == "Camera" || source == "camera" {
            fuckYouMopriaForMakingThisSoComplicated = "scan:Camera"
        }
        else {
            fuckYouMopriaForMakingThisSoComplicated = source
        }
        
        let body = """
    <scan:ScanSettings xmlns:pwg="http://www.pwg.org/schemas/2010/12/sm" xmlns:scan="http://schemas.hp.com/imaging/escl/2011/05/03">
      <pwg:Version>\(version)</pwg:Version>
      <scan:Intent>\(intent)</scan:Intent>
      <pwg:ScanRegions>
        <pwg:ScanRegion>
          <pwg:XOffset>\(XOffset)</pwg:XOffset>
          <pwg:YOffset>\(YOffset)</pwg:YOffset>
          <pwg:Width>\(width)</pwg:Width>
          <pwg:Height>\(height)</pwg:Height>
          <pwg:ContentRegionUnits>escl:ThreeHundredthsOfInches</pwg:ContentRegionUnits>
        </pwg:ScanRegion>
      </pwg:ScanRegions>
      <pwg:InputSource>\(fuckYouMopriaForMakingThisSoComplicated)</pwg:InputSource>
      <pwg:DocumentFormat>\(format)</pwg:DocumentFormat>
      <scan:ColorMode>\(colorMode)</scan:ColorMode>
      <scan:XResolution>\(resolution)</scan:XResolution>
      <scan:YResolution>\(resolution)</scan:YResolution>
    </scan:ScanSettings>
    """
        print("body: \(body)")
        print("url: \(self.baseURI+uri)")
        urlRequest.httpBody = body.data(using: .utf8)
        
        let configuration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.init())
        var responseurl: String = ""
        var path: URL?
        let sem = DispatchSemaphore.init(value: 0)
        print("preparing task..")
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            defer { sem.signal() }
            print("test")
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard(200 ... 299) ~= response.statusCode else {
                print("Statuscode should be 2xx but is \(response.statusCode)")
                print("response = \(response)")
                return
            }
            
            
            self.responseURL = (response.allHeaderFields["Location"] as! String).replacingOccurrences(of: "http:", with: "https:") + "/NextDocument"
            print("Location: \(self.responseURL)")
            
            var responseCode: Int = 0
            
            while responseCode != 404 {
                sleep(2)
                (path, responseCode) = self.sendGetRequest(uri: self.responseURL, format: format)
                print(responseCode)
            }
                        
        }
        
        task.resume()
        sem.wait()
        
        return path
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.serverTrust == nil {
            completionHandler(.useCredential, nil)
        } else {
            let trust: SecTrust = challenge.protectionSpace.serverTrust!
            let credential = URLCredential(trust: trust)
            completionHandler(.useCredential, credential)
        }
    }
}
