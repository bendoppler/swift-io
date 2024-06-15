//
//  ContentView.swift
//  Layers
//
//  Created by Chris Eidhof on 09.10.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var invalidAttempts = 0

    var body: some View {
        VStack {
            Button {
                self.invalidAttempts += 1
            } label: {
                Text("Shake")
            }
            Rectangle()
                .fill(.purple)
                .frame(width: 200, height: 200)
                .modifier(ShakeEffect(shakes: invalidAttempts * 2))
                .animation(.linear)
        }
    }
}

struct ShakeEffect: GeometryEffect {
    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: -30 * sin(position * 2 * .pi), y: 0))
    }

    init(shakes: Int) {
        position = CGFloat(shakes)
    }

    var position: CGFloat
    var animatableData: CGFloat {
        get { position }
        set { position = newValue }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
