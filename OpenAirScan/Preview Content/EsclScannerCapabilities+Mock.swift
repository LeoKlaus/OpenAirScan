//
//  EsclScannerCapabilities+Mock.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftESCL
import Foundation

extension EsclScannerCapabilities {
    
    static let mock = EsclScannerCapabilities(
        version: "2.9",
        makeAndModel: "EPSON ET-4800 Series",
        manufacturer: "EPSON",
        serialNumber: "581354565123465",
        uuid: UUID().uuidString,
        adminUri: "http://epson.local.:80/PRESENTATION/BONJOUR",
        iconUri: "https://epson.local.:443/PRESENTATION/AIRPRINT/PRINTER_128.PNG",
        certifications: [
            MopriaCertification(
                name: "mopria-certified-scan",
                version: "1.4"
            )
        ],
        sourceCapabilities: [
            .platen: .mockFlatbed,
            .adf: .mockAdf,
            .adfDuplex: .mockAdfDuplex
        ],
        brightnessSupport: SteppedRange(
            min: -100,
            max: 100,
            normal: 0,
            step: 1
        ),
        compressionFactorSupport: SteppedRange(
            min: 0,
            max: 3,
            normal: 2,
            step: 1
        ),
        contrastSupport: SteppedRange(
            min: -100,
            max: 100,
            normal: 0,
            step: 1
        ),
        sharpenSupport: SteppedRange(
            min: 0,
            max: 3,
            normal: 2,
            step: 1
        ),
        thresholdSupport: SteppedRange(
            min: 0,
            max: 255,
            normal: 186,
            step: 1
        )
    )
}
