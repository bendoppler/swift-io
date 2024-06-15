//
//  ContentView.swift
//  Badge
//
//  Created by Chris Eidhof on 01.08.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct BadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { p in
            p.move(to: rect.origin)
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y))
            p.addLine(to: CGPoint(x: rect.origin.x, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct PreviewBadge: View {
    var body: some View {
        ZStack {
            BadgeShape().foregroundColor(.orange)
            Text("Preview")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 30)
                .rotationEffect(Angle(degrees: -45))
        }
    }
}

struct ContentView: View {
    @State var size: CGFloat = 100
    var body: some View {
        VStack {
            ZStack(alignment: .topLeading) {
                Image(uiImage: UIImage(named: "test.jpg")!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                PreviewBadge()
                    .frame(width: size, height: size)
            }.clipped()
            Slider(value: $size, in: 0...200)
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
