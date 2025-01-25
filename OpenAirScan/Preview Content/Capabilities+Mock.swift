//
//  Capabilities+Mock.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 21.01.25.
//

import SwiftESCL
import UniformTypeIdentifiers

extension Capabilities {
    static let mockFlatbed = Capabilities(
        colorModes: [.blackAndWhite, .grayscale8, .rgb24],
        documentFormats: [.pdf, .jpeg],
        supportedResolutions: [100, 200, 300, 600, 1200],
        supportedIntents: [.document, .textAndGraphic, .businessCard, .photo, .preview],
        colorSpaces: [.sRGB],
        ccdChannels: [.ntsc],
        binaryRendering: [.threshold, .halftone],
        contentTypes: [.photo, .text, .textAndPhoto],
        justification: nil,
        feederCapacity: nil,
        adfOptions: [],
        minWidth: 96,
        maxWidth: 2550,
        minHeight: 96,
        maxHeight: 3510,
        maxXOffset: 2454,
        maxYOffset: 3414,
        maxOpticalXResolution: 1200,
        maxOpticalYResolution: 1200,
        riskyLeftMargin: 17,
        riskyRightMargin: 17,
        riskyTopMargin: 35,
        riskyBottomMargin: 35,
        maxScanRegions: 1
    )
    
    static let mockAdf = Capabilities(
        colorModes: [.blackAndWhite, .grayscale8, .rgb24],
        documentFormats: [.pdf, .jpeg],
        supportedResolutions: [100, 200, 300, 600],
        supportedIntents: [.document, .textAndGraphic, .photo, .preview],
        colorSpaces: [.sRGB],
        ccdChannels: [.ntsc],
        binaryRendering: [.threshold, .halftone],
        contentTypes: [.photo, .text, .textAndPhoto],
        justification: Justification(
            xImagePosition: .right,
            yImagePosition: .top
        ),
        feederCapacity: 50,
        adfOptions: [
            .detectPaperLoaded
        ],
        minWidth: 96,
        maxWidth: 2550,
        minHeight: 96,
        maxHeight: 3510,
        maxXOffset: 2454,
        maxYOffset: 3414,
        maxOpticalXResolution: 1200,
        maxOpticalYResolution: 1200,
        riskyLeftMargin: 17,
        riskyRightMargin: 17,
        riskyTopMargin: 35,
        riskyBottomMargin: 35,
        maxScanRegions: 1
    )
    
    static let mockAdfDuplex = Capabilities(
        colorModes: [.blackAndWhite, .grayscale8, .rgb24],
        documentFormats: [.pdf, .jpeg],
        supportedResolutions: [100, 200, 300],
        supportedIntents: [.document, .textAndGraphic, .photo, .preview],
        colorSpaces: [.sRGB],
        ccdChannels: [.ntsc],
        binaryRendering: [.threshold, .halftone],
        contentTypes: [.photo, .text, .textAndPhoto],
        justification: Justification(
            xImagePosition: .right,
            yImagePosition: .top
        ),
        feederCapacity: 50,
        adfOptions: [
            .detectPaperLoaded
        ],
        minWidth: 96,
        maxWidth: 2550,
        minHeight: 96,
        maxHeight: 3510,
        maxXOffset: 2454,
        maxYOffset: 3414,
        maxOpticalXResolution: 1200,
        maxOpticalYResolution: 1200,
        riskyLeftMargin: 17,
        riskyRightMargin: 17,
        riskyTopMargin: 35,
        riskyBottomMargin: 35,
        maxScanRegions: 1
    )
}
