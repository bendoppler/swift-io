//
//  ContentView.swift
//  Buttons
//
//  Created by Chris Eidhof on 22.02.21.
//

import SwiftUI

struct HideLabels: PreferenceKey, EnvironmentKey {
    static let defaultValue = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension EnvironmentValues {
    var hideLabels: Bool {
        get { self[HideLabels.self] }
        set { self[HideLabels.self] = newValue }
    }
}

struct IconButton: View {
    var iconName: String
    var text: String
    @Environment(\.hideLabels) var hideLabel
    var textAndLabel: some View {
        HStack {
            Image(systemName: iconName)
            Text(text)
                .fixedSize()
        }.padding()
    }
    
    var body: some View {
        textAndLabel
        .hidden()
        .overlay(GeometryReader { proxy in
            let outOfBounds = proxy.frame(in: .named("Space")).minX < 0
            HStack {
                Image(systemName: iconName)
                if !hideLabel {
                    Text(text)
                        .fixedSize()
                }
            }.padding()
            .frame(width: proxy.size.width, alignment: .center)
            .preference(key: HideLabels.self, value: outOfBounds)
        })
        .frame(width: 0)
        .frame(maxWidth: .infinity)
        .coordinateSpace(name: "Space")
        .background(RoundedRectangle(cornerRadius: 5).fill(Color.gray))
    }
}

struct ContentView: View {
    @State var hideLabels = false
    var body: some View {
        HStack {
            IconButton(iconName: "play.fill", text: "Play")
            IconButton(iconName: "pause.fill", text: "Pause")
            IconButton(iconName: "stop.fill", text: "Stop")
        }.padding()
        .frame(maxWidth: .infinity)
        .environment(\.hideLabels, hideLabels)
        .onPreferenceChange(HideLabels.self) { self.hideLabels = $0 }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
