//
//  LoadingOverlay.swift
//  Paperless-App
//
//  Created by Leo Wehrfritz on 02.07.22.
//  Copyright © 2022 me.wehrfritz. All rights reserved.
//

import SwiftUI

struct LoadingOverlay: View {
    
    @State private var text = ""
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            Text("")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            Text("Waiting for the scanner\(text)")
                .font(.system(size: 17)).bold()
                .frame(width: 300, height: 100)
                .foregroundColor(Color.blue)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10.0))
                .transition(.slide)
                .onReceive(timer, perform: { (_) in
                    if self.text.count == 3 {
                        self.text = ""
                    }
                    else {
                        self.text += "."
                    }
                })
                .onAppear(){
                    self.text = "."
                }
        }
    }
}

struct LoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        LoadingOverlay()
    }
}
