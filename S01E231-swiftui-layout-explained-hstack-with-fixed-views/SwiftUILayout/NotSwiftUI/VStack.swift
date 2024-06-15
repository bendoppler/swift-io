//
//  VStack.swift
//  SwiftUILayout
//
//  Created by Do Thai Bao on 24/01/2023.
//

import Foundation
import SwiftUI

struct VStack_: View_, BuiltinView {

    var children: [AnyView_]
    var alignment: HorizontalAlignment_ = .center
    let spacing: CGFloat? = 0

    @LayoutState var sizes: [CGSize] = []

    var layoutPriority: Double { 0 }

    func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        fatalError("TODO")
    }

    func render(context: RenderingContext, size: CGSize) {
        let stackX = alignment.alignmentID.defaultValue(in: size)
        var currentY: CGFloat = size.height
        for idx in children.indices {
            let child = children[idx]
            let childSize = sizes[idx]
            let childX = alignment.alignmentID.defaultValue(in: childSize)
            context.saveGState()
            context.translateBy(x: stackX - childX, y: currentY - childSize.height)
            child.render(context: context, size: childSize)
            context.restoreGState()
            currentY -= childSize.height
        }
    }

    func size(proposed: ProposedSize) -> CGSize {
        layout(proposed: proposed)
        let width: CGFloat = sizes.reduce(0) { max($0, $1.width) }
        let height: CGFloat = sizes.reduce(0) { $0 + $1.height }
        return CGSize(width: width, height: height)
    }

    func layout(proposed: ProposedSize) {
        let flexibility: [CGFloat] =  children.map { child in
            let lowerSize = child.size(proposed: ProposedSize(width: proposed.width, height: 0))
            let upperSize = child.size(proposed: ProposedSize(width: proposed.width, height: .greatestFiniteMagnitude))
            return upperSize.height - lowerSize.height
        }

        var remainingIndices = children.indices.sorted { l, r in
            return flexibility[l] < flexibility[r]
        }

        var remainingHeight = proposed.height! // TODO
        var sizes: [CGSize] = Array(repeating: .zero, count: children.count)
        while !remainingIndices.isEmpty {
            let height = remainingHeight / CGFloat(remainingIndices.count)
            let idx = remainingIndices.removeFirst()
            let child = children[idx]
            let size = child.size(proposed: ProposedSize(width: proposed.width, height: height))
            sizes[idx] = size
            remainingHeight -= size.height
            if remainingHeight < 0 { remainingHeight = 0 }
        }
        self.sizes = sizes
    }

    var swiftUI: some View {
        VStack(alignment: alignment.swiftUI, spacing: spacing) {
            ForEach(children.indices, id: \.self) { idx in
                children[idx].swiftUI
            }
        }
    }

}
