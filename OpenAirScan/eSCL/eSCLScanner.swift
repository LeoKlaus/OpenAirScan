//
//  eSCLScanner.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 14.07.22.
//  Licensed under the MIT License
//

import Foundation
import Combine

/**
 An object representing a single eSCL scanner. It contains no information but the scanners hostname/ip.
 The methods of this class are the way you can interact with the device.
 */
class esclScanner: NSObject, URLSessionDelegate {
    var baseURI: String

    init(ip: String, root: String) {
        self.baseURI = "https://\(ip)/\(root)/"
    }

    enum ScannerStatus {
        case Idle
        case Processing
        case Testing
        case Stopped
        case Down
    }
    
    /**
     This method retrieves the capabilities of a scanner.
     - Returns:A "scanner" object with all parsed capabilities. Currently, not all available capabilities are stored or parsed. For an exact overview of what is parsed or stored, see the declerations of the Scanner struct or CapabilityParser.
     */
    func getCapabilities() -> Scanner {
        
        var capabilities = Scanner()
        
        var urlRequest = URLRequest(url: URL(string: self.baseURI + "ScannerCapabilities")!)
        
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
                return
            }
            
            let parser = CapabilityParser(data: data)
            let success:Bool = parser.parse()
            if success {
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
     - Returns:A string with the scanners current status
     */
    func getStatus() -> ScannerStatus {
        
        var status = ScannerStatus.Down
        
        var urlRequest = URLRequest(url: URL(string: self.baseURI + "ScannerStatus")!)
        
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
                print("Encountered an error while fetching Status: ", error ?? URLError(.badServerResponse))
                return
            }
            
            guard(200 ... 299) ~= response.statusCode else {
                print("Encountered an error while fetching Status: Server returned \(response.statusCode)")
                return
            }
            
            let parser = StatusParser(data: data)
            let success:Bool = parser.parse()
            if success {
                //status = parser.status
                if parser.status == "Idle" {
                    status = ScannerStatus.Idle
                }
                else if parser.status == "Processing" {
                    status = ScannerStatus.Processing
                }
                else if parser.status == "Testing" {
                    status = ScannerStatus.Testing
                }
                else if parser.status == "Stopped" {
                    status = ScannerStatus.Stopped
                }
                else {
                    status = ScannerStatus.Down
                }
            } else {
                print("Encountered an error while parsing status response")
            }
        }
        
        task.resume()
        sem.wait()
        
        return status
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
                print("Get request returned status \(response.statusCode)")
                return
            }
            
            imageData = data
        }
        
        task.resume()
        sem.wait()
        return (imageData, responseCode)
    }
    
    /**
     This method sends a POST request to the scanner (this is what actually initiates the scan). And returns the results as binary data. The body of the request is generated using the following parameters:
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
     - Returns: A tuple containing the the URL to the scan and the response code of the last request (which should be 200).
     */
    func sendPostRequest(resolution: String = "300", colorMode: String = "RGB24", format: String = "application/pdf", version: String = "2.5", source: String = "Platen", width: Int = 2480, height: Int = 3508, XOffset: String = "0", YOffset: String = "0", intent: String = "Document") -> (String, Int) {

        var urlRequest = URLRequest(url: URL(string: self.baseURI+"ScanJobs")!)
        
        var responseCode: Int = 0
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        
        var responseURL: String = ""
        
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
        
        urlRequest.httpBody = body.data(using: .utf8)
        
        let configuration = URLSessionConfiguration.default
        
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.init())
        
        let sem = DispatchSemaphore.init(value: 0)
        
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            defer { sem.signal() }
            guard
                let response = response as? HTTPURLResponse,
                error == nil
            else {
                print("error", error ?? URLError(.badServerResponse))
                return
            }
            
            guard(200 ... 299) ~= response.statusCode else {
                print("POST request returned stauts \(response.statusCode)")
                responseCode = response.statusCode
                return
            }
            
            // The scanner returns the url to the document under the "Location" header. One of the devices I tested with returned the location with "http" as the protocol even though eSCL requires HTTPS
            // So apparantly, these things can't be trusted
            responseURL = (response.allHeaderFields["Location"] as! String).replacingOccurrences(of: "http:", with: "https:") + "/NextDocument"
            responseCode = response.statusCode
            print("Location: \(responseURL)")
        }
        
        task.resume()
        sem.wait()
        
        return (responseURL, responseCode)
    }
    
    /**
     Method to perform an entire scan operation.
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
     - Returns: A tuple containing the Binary Data of the scanned image and the last http response code
     */
    func scanDocument(resolution: String = "300", colorMode: String = "RGB24", format: String = "application/pdf", version: String = "2.5", source: String = "Platen", width: Int = 2480, height: Int = 3508, XOffset: String = "0", YOffset: String = "0", intent: String = "Document") -> (Data,Int) {
        
        var data = Data()
        
        if getStatus() == ScannerStatus.Idle {
            print("Scanner is not idle but \(getStatus())")
            return (data, 503)
        }
        
        let (url, postResponse) = self.sendPostRequest(resolution: resolution, colorMode: colorMode, format: format, version: version, source: source, width: width, height: height, intent: intent)
        
        if postResponse != 201 {
            print("Scanner didn't accept the job. \(postResponse)")
            return (data, postResponse)
        }
        
        var responseCode = 0
        while responseCode != 200 {
            sleep(2)
            (data, responseCode) = self.sendGetRequest(uri: url)
            print(responseCode)
        }
        // My scanners won't reach idle after completing a scan without this
        _ = self.sendGetRequest(uri: url)
        
        return (data, responseCode)
    }
    
    /**
     Method to perform an entire scan operation.
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
     - Parameter filePath: Path at which the file should be stored. If not specified, the file will be stored in the document root under the name "scan-YY-MM-dd-HH-mm-ss.fileExtension"
     - Returns: A tuple containing the URL to the file created and the last http response code
     */
    func scanDocumentAndSaveFile(resolution: String = "300", colorMode: String = "RGB24", format: String = "application/pdf", version: String, source: String = "Platen", width: Int = 2480, height: Int = 3508, XOffset: Int = 0, YOffset: Int = 0, intent: String = "Document", filePath: URL? = nil) -> (URL?, Int) {
        
        let status = self.getStatus()
        if status != ScannerStatus.Idle {
            print("Scanner is not idle but \(status)")
            return (nil, 503)
        }
        
        let (url, postResponse) = self.sendPostRequest(resolution: resolution, colorMode: colorMode, format: format, version: version, source: source, width: width, height: height, intent: intent)
        
        if postResponse != 201 {
            print("Scanner didn't accept the job. \(postResponse)")
            return (nil, postResponse)
        }
        
        var data = Data()
        var responseCode = 0
        while responseCode != 200 {
            sleep(2)
            (data, responseCode) = self.sendGetRequest(uri: url)
            print(responseCode)
        }
        // My scanners won't reach idle after completing a scan without this
        _ = self.sendGetRequest(uri: url)
        
        var path: URL
        if filePath == nil {
            let fileExtension = (format == "application/pdf") ? ".pdf" : ".jpeg"
            
            // This is just used for determinining a file name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YY-MM-dd-HH-mm-ss"
            let filename = "scan-" + dateFormatter.string(from: Date.now) + fileExtension
            
            path = FileManager.default.urls(for: .documentDirectory,
                                                in: .userDomainMask)[0].appendingPathComponent(filename)
        } else {
            path = filePath!
        }
        
        try? data.write(to: path)
        
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
