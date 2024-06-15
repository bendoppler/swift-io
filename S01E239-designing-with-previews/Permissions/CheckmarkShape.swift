//
//  CheckmarkShape.swift
//  Permissions
//
//  Created by Do Thai Bao on 12/02/2023.
//

import SwiftUI

struct Checkmark: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let thirdX = rect.minX + rect.width / 3
            p.move(to: CGPoint(x: rect.minX, y: rect.midY))
            p.addLine(to: CGPoint(x: thirdX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
    }
}

struct Checkmark_Previews: PreviewProvider {
    static var previews: some View {
        Checkmark()
            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            .padding()
            .frame(width: 100, height: 100)
    }
}
