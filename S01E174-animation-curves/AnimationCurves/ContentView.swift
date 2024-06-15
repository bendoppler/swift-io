//
//  ContentView.swift
//  AdditiveAnimations
//
//  Created by Chris Eidhof on 10.10.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct RecordingEffect: GeometryEffect {
    var callback: (CGFloat) -> ()
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        callback(animatableData)
        return ProjectionTransform()
    }
}

struct ContentView: View {
    @State var flag = false
    @State var recording: [(CFTimeInterval, CGFloat)] = []
    var body: some View {
        VStack {
            Rectangle()
                .fill(.black)
                .frame(width: 100, height: 100)
                .offset(y: flag ? 300 : 0)
                .modifier(RecordingEffect(callback: { value in
                    DispatchQueue.main.async {
                        self.recording.append((CACurrentMediaTime(), value))
                    }
                }, animatableData: flag ? 1 : 0))
                .animation(.default.repeatCount(5))
            Plot(data: recording)
                .stroke(.red, lineWidth: 2)
                .frame(width: 300, height: 300)
                .border(.gray, width: 1)
            Spacer()
            Toggle(isOn: $flag) {
                Text("Flag")
            }
        }
    }
}

struct Plot: Shape {
    var data: [(CGFloat, CGFloat)] = []
    init(data: [(CFTimeInterval, CGFloat)]) {
        guard let last = data.last else {
            return
        }
        let maxX = last.0
        let slice = data.drop {
            $0.0 < maxX - 3
        }
        guard let minX = slice.first?.0 else { return }
        self.data = slice.map {
            (CGFloat(($0.0 - minX) / (maxX - minX)), $0.1)
        }
    }

    func path(in rect: CGRect) -> Path {
        guard !data.isEmpty else { return Path() }
        let points = data.map {
            CGPoint(x: $0.0 * rect.width, y: $0.1 * rect.height)
        }
        return Path { p in
            p.move(to: points[0])
            p.addLines(points)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
