//
//  Grid.swift
//  SwiftUILayout
//
//  Created by Chris Eidhof on 05.01.21.
//

import SwiftUI

struct VGrid: BuiltinView, View_ {
    var columns: [CGFloat]
    var content: [AnyView_]
    
    func size(proposed: ProposedSize) -> CGSize {
        let width = columns.reduce(0,+)
        var remainingViews = content
        var height: CGFloat = 0
        while !remainingViews.isEmpty {
            let lineViews = remainingViews.prefix(columns.count)
            remainingViews.removeFirst(lineViews.count)
            var lineHeight: CGFloat = 0
            for (column, view) in zip(columns, lineViews) {
                lineHeight = max(lineHeight, view.size(proposed: ProposedSize(width: column, height: nil)).height)
            }
            height += lineHeight
        }
        return CGSize(width: max(proposed.orDefault.width, width), height: height)
    }
    
    func render(context: RenderingContext, size: CGSize) {
        var remainingViews = content
        var offsetY: CGFloat = 0
        while !remainingViews.isEmpty {
            var offsetX: CGFloat = 0
            let lineViews = remainingViews.prefix(columns.count)
            remainingViews.removeFirst(lineViews.count)
            var lineHeight: CGFloat = 0
            for (column, view) in zip(columns, lineViews) {
                lineHeight = max(lineHeight, view.size(proposed: ProposedSize(width: column, height: nil)).height)
            }
            for (column, view) in zip(columns, lineViews) {
                let childSize = view.size(proposed: ProposedSize(width: column, height: lineHeight))
                context.saveGState()
                context.translateBy(x: offsetX, y: offsetY)
                view.render(context: context, size: childSize)
                context.restoreGState()
                offsetX += childSize.width
            }
            offsetY += lineHeight
        }
    }
    
    func customAlignment(for alignment: HorizontalAlignment_, in size: CGSize) -> CGFloat? {
        return nil
    }
    
    var layoutPriority: Double { 0 }
    
    var swiftUI: some View {
        let items = columns.map { GridItem(.fixed($0), spacing: 0, alignment: .leading)}
        return LazyVGrid(columns: items, alignment: .leading, spacing: 0, pinnedViews: []) {
            ForEach(content.indices, id: \.self) { idx in
                content[idx].swiftUI
            }
        }
    }
}
