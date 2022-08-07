//
//  Test.swift
//  AirScanTest
//
//  Created by Leo Wehrfritz on 14.07.22.
//

import Foundation
import Combine

/**
 An object representing a single eSCL scanner. It contains no information but the scanners hostname/ip.
 The methods of this class are the way you can interact with the device.
 */
class esclScanner: NSObject, URLSessionDelegate {
    var baseURI: String
    var responseURL = ""

    init(ip: String) {
        self.baseURI = "https://\(ip)"
    }
    
    
    /**
     This method retrieves the capabilities of a scanner.
     - Parameter uri: A string with the absolute URL to the ScannerCapabilities page of a scanner, including the protocol. For most devices, that should be "https://[ip]/eSCL/ScannerCapabilities".
     - Returns:A "scanner" object with all parsed capabilities. Currently, not all available capabilities are stored or parsed. For an exact overview of what is parsed or stored, see the declerations of the Scanner struct or CapabilityParser.
     */
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
                return
            }
            
            let parser = CapabilityParser(data: data)
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
    
    /**
     This method query the scanners status.
     - Parameter uri: A string with the absolute URL to the ScannerStatus page of a scanner, including the protocol. For most devices, that should be "https://[ip]/eSCL/ScannerCapabilities".
     - Returns:A string with the scanners current status
     */
    func getStatus(uri: String) -> String {
        // TODO: Implement this
        return ""
    }
    
    /**
     This method sends a GET request to the scanner. It is used to retrieve the scanned image.
     - Parameter uri: A string with the aboslute URL to the scanned image. This URL is created by the scanner after posting a scan-request and is available for a short time only (I'm guessing it can only be accessed once.)
     - Returns: A tuple containing the binary data of the image and the response code of the last request (which should be 200).
     */
    func sendGetRequest(uri: String) -> (Data, Int) {
        
        var urlRequest = URLRequest(url: URL(string: uri)!)
        var imageData = Data()
        
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
            
            imageData = data
        }
        
        task.resume()
        sem.wait()
        return (imageData, responseCode)
    }
    
    /**
     This method sends a GET request to the scanner. It is used to retrieve the scanned image and store it on disk.
     - Parameter uri: A string with the aboslute URL to the scanned image. This URL is created by the scanner after posting a scan-request and is available for a short time only (I'm guessing it can only be accessed once.)
     - Parameter format: A string containing the mimetype of the scanned image. This is only used to determine the file extension for storage.
     - Returns: A tuple containing the URL to the file created in storage and the response code of the last request (which should be 200).
     */
    func sendGetRequestAndSaveFile(uri: String, format: String) -> (URL?, Int) {

        let fileExtension = (format == "application/pdf") ? ".pdf" : ".jpeg"
        
        // This is just used for determinining a file name
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YY-MM-dd-HH-mm-ss"
        let filename = "scan-" + dateFormatter.string(from: Date.now) + fileExtension
        
        let path = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0].appendingPathComponent(filename)
        
        let (data, responseCode) = self.sendGetRequest(uri: uri)
        
        try? data.write(to: path)
        
        return (path, responseCode)
    }
    /**
     This method sends a POST request to the scanner (this is what actually initiates the scan). And stores the resulting file on disk. The body of the request is generated using the following parameters:
     - Parameter uri: A string containing the relative path to the "ScanJobs"-Page of the scanner. This should be "/eSCL/ScanJobs" for most devices.
     - Parameter resolution: A string containing the desired resolution in DPI. This could be easily changed to take an integer instead, but for my purposes, a String was easier to handle.
     - Parameter colorMode: A string containing the desired color mode. For most scanners, the available options here are "BlackAndWhite1", "Grayscale8" and "RGB24".
     - Parameter format: The mimetype of the file the scanner should produce. My scanners only support "application/pdf" and "image/jpg".
     - Parameter version: The version of the eSCL protocol to be used.
     - Parameter source: The source to use for the scan. This can either be "Platen" (that's flatbed), "Adf" or "Camera".
     - Parameter width: Width of the desired output in pixels at 300 DPI. This can be converted to inches by dividing by 300, to centimeters by dividing by 118.
     - Parameter height: Height of the desired output in pixels at 300 DPI.
     - Parameter XOffset: Offset on the X-Axis. It is necessary to set this for some scanners.
     - Parameter YOffset: Offset on the Y-Axis.
     - Parameter intent: This helps the scanner auto-determine settings for the scan. Technically, version and intent should suffice for a valid request. To my understanding, the defaults set by an intent are ignored as soon as values are provided.
     - Returns: A tuple containing the URL to the created file and the response code of the last request (which should be 200).
     */
    func sendPostRequest(uri: String, resolution: String = "300", colorMode: String = "RGB24", format: String = "application/pdf", version: String = "2.5", source: String = "Platen", width: Int = 2480, height: Int = 3508, XOffset: String = "0", YOffset: String = "0", intent: String = "Document") -> (URL?, Int) {
        print("sendControllerPostRequest")
        var urlRequest = URLRequest(url: URL(string: self.baseURI+uri)!)
        
        var responseCode: Int = 0
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        
        // Scanners will report supported sources as "Adf" or "Camera" but expect "Feeder" or "scan:Camera" for actual requests
        // It is beyond me why the Mopria Alliance chose to do this
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
        
        // The base structure of the body
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
        var path: URL?
        let sem = DispatchSemaphore.init(value: 0)
        print("preparing task..")
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            defer { sem.signal() }
            print("test")
            guard
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard(200 ... 299) ~= response.statusCode else {
                print("Statuscode should be 2xx but is \(response.statusCode)")
                print("response = \(response)")
                responseCode = response.statusCode
                return
            }
            
            // The scanner returns the url to the document under the "Location" header. One of the devices I tested with returned the location with "http" as the protocol even though eSCL requires HTTPS
            // So apparantly, these things can't be trusted
            self.responseURL = (response.allHeaderFields["Location"] as! String).replacingOccurrences(of: "http:", with: "https:") + "/NextDocument"
            print("Location: \(self.responseURL)")
            
            
            while responseCode != 200 {
                sleep(2)
                (path, responseCode) = self.sendGetRequestAndSaveFile(uri: self.responseURL, format: format)
                print(responseCode)
            }
            // My scanner wont return to the idle status without an additional request after the successful one.
            self.sendGetRequest(uri: self.responseURL)
        }
        
        task.resume()
        sem.wait()
        
        return (path, responseCode)
    }
    
    // It is necessary to build a custom URLSession for this as the self signed certificates the scanners use are obviously not trusted by default.
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
