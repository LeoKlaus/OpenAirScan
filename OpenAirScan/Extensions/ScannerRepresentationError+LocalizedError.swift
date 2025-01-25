//
//  ScannerRepresentationError+LocalizedError.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import Foundation
import SwiftESCL

extension ScannerRepresentationError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noAdminUrl:
            String(localized: "No admin URL found")
        case .invalidAdminUrl:
            String(localized: "Invalid admin URL")
        case .noUuid:
            String(localized: "No UUID found")
        case .noRoot:
            String(localized: "No root found")
        case .invalidResponse:
            String(localized: "Invalid response")
        case .notFound:
            String(localized: "Scanner couldn't find the requested ressource")
        case .serviceUnavailable:
            String(localized: "Scanner is unavailable")
        case .unexpectedStatus(let int, let data):
            if let data {
                String(localized: "Scanner returned an unexpected status code \(int). Reponse body: \(String(data: data, encoding: .utf8) ?? "<binary data>")")
            } else {
                String(localized: "Scanner returned an unexpected status code \(int).")
            }
        case .invalidUrl:
            String(localized: "Invalid URL")
        case .scanJobNotFound:
            String(localized: "Scan job not found")
        case .unexpectedScanJobState(let scanJobState):
            String(localized: "Unexpected scan job state: \(scanJobState.rawValue)")
        }
    }
}
