//
//  TabStateHandler.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 25.01.25.
//

import SwiftUI

class TabStateHandler: ObservableObject {
    @Published var currentTab: ContentViewTab = .scanning
}
