//
//  ActivityViewHandler.swift
//  OpenAirScan
//
//  Created by Leo Wehrfritz on 08.06.22.
//  Licensed under the MIT License
//

import Foundation
import SwiftUI
/// This is used to wrap the share sheet
struct ActivityViewHandler: UIViewControllerRepresentable {
    var itemsToShare: [Any]
    var servicesToShareItem: [UIActivity]? = nil
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewHandler>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemsToShare, applicationActivities: servicesToShareItem)
        return controller
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController,
                                context: UIViewControllerRepresentableContext<ActivityViewHandler>) {}
}
