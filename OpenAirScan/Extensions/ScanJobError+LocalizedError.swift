//
//  ScanJobError+LocalizedError.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import Foundation
import SwiftESCL

extension ScanJobError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .scannerNotReady(let scannerState):
            String(localized: "Scanner is not ready: \(scannerState?.rawValue ?? "unknown state")")
        case .noJobIdReceived:
            String(localized: "Scanner accepted the job but returned no job ID")
        case .conflictingArguments:
            String(localized: "Scanner didn't accept the job due to conflicting arguments")
        case .deviceUnavailable:
            String(localized: "Scanner is currently unavailable")
        case .cancelled:
            String(localized: "The scan job was cancelled")
        }
    }
}
