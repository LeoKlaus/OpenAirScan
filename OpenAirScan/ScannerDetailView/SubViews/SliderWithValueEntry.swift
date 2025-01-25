//
//  SliderWithValueEntry.swift
//  OpenAirScan-next
//
//  Created by Leo Wehrfritz on 22.01.25.
//

import SwiftUI
import SwiftESCL

struct SliderWithValueEntry: View {
    
    let text: String
    let systemImage: String
    
    let support: SteppedRange
    
    @Binding var value: Int?
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label(self.text, systemImage: self.systemImage)
                TextField(
                    self.text,
                    value: Binding(get: {
                        self.value ?? self.support.normal
                    }, set: {
                        self.value = $0
                    }),
                    format: .number)
                .foregroundStyle(.secondary)
                .keyboardType(.numberPad)
                Button {
                    self.value = nil
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding<Double>(get: {
                    return Double(self.value ?? self.support.normal)
                }, set: {
                    self.value = Int($0)
                }),
                in: Double(self.support.min)...Double(self.support.max),
                step: Double(self.support.step)) {
                    Text(text)
                } minimumValueLabel: {
                    Text("\(self.support.min)")
                } maximumValueLabel: {
                    Text("\(self.support.max)")
                }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var scanSettings = ScanSettings(source: .adf, version: "2.0")
    
    List {
        SliderWithValueEntry(text: "Brightness", systemImage: "sun.max", support: SteppedRange(min: -100, max: 100, normal: 0, step: 10), value: $scanSettings.brightness)
    }
}
