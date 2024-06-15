//
//  ContentView.swift
//  FlowLayoutST
//
//  Created by Chris Eidhof on 22.08.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct FlowLayout {
    let spacing: UIOffset
    let containerSize: CGSize

    init(containerSize: CGSize, spacing: UIOffset = UIOffset(horizontal: 10, vertical: 10)) {
        self.spacing = spacing
        self.containerSize = containerSize
    }

    var currentX = 0 as CGFloat
    var currentY = 0 as CGFloat
    var lineHeight = 0 as CGFloat

    mutating func add(element size: CGSize) -> CGRect {
        if currentX + size.width > containerSize.width {
            currentX = 0
            currentY += lineHeight + spacing.vertical
            lineHeight = 0
        }
        defer {
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing.horizontal
        }
        return CGRect(origin: CGPoint(x: currentX, y: currentY), size: size)
    }

    var size: CGSize {
        return CGSize(width: containerSize.width, height: currentY + lineHeight)
    }
}

func flowLayout<Elements>(
    for elements: Elements,
    containerSize: CGSize,
    sizes: [Elements.Element.ID: CGSize]
) -> [(Elements.Element.ID, CGSize)] where Elements: RandomAccessCollection, Elements.Element: Identifiable {
    var state = FlowLayout(containerSize: containerSize)
    var result: [(Elements.Element.ID, CGSize)] = []
    for element in elements {
        let rect = state.add(element: sizes[element.id] ?? .zero)
        result.append((element.id, CGSize(width: rect.origin.x, height: rect.origin.y)))
    }
    return result
}

extension View {
    func offset(_ point: CGPoint) -> some View {
        return offset(x: point.x, y: point.y)
    }
}

struct CollectionView<Elements, Content>: View where Elements: RandomAccessCollection, Content: View, Elements.Element: Identifiable {
    var data: Elements
    var didMove: (Elements.Index, Elements.Index) -> ()
    var content: (Elements.Element) -> Content
    @State private var sizes: [Elements.Element.ID: CGSize] = [:]
    @State private var dragState: (id: Elements.Element.ID, translation: CGSize, location: CGPoint)? = nil

    private func dragOffset(for id: Elements.Element.ID) -> CGSize? {
        guard let state = dragState, state.id == id else { return nil }
        return state.translation
    }

    private func bodyHelper(containerSize: CGSize, offsets: [(Elements.Element.ID, CGSize)]) -> some View {
        var insertionPoint: (id: Elements.Element.ID, offset: CGSize)? {
            guard let dragState = dragState else {
                return nil
            }
            for offset in offsets.reversed() {
                if offset.1.width < dragState.location.x && offset.1.height < dragState.location.y {
                    return (id: offset.0, offset: offset.1)
                }
            }
            return nil
        }

        return ZStack(alignment: .topLeading) {
            ForEach(data) { element in
                PropagateSize(content: self.content(element), id: element.id)
                    .offset(offsets.first { element.id == $0.0 }?.1 ?? .zero)
                    .offset(dragOffset(for: element.id) ?? .zero)
                    .gesture(DragGesture().onChanged { value in
                        self.dragState = (element.id, value.translation, value.location)
                    }.onEnded { _ in
                        if let oldIndex = self.data.firstIndex(where: { $0.id == self.dragState?.id }),
                           let newIndex = self.data.firstIndex(where:{ $0.id == insertionPoint?.id }) {
                            self.didMove(oldIndex, newIndex)
                        }
                        self.dragState = nil
                    })
            }
            if let insertionPoint = insertionPoint {
                Rectangle()
                    .fill(Color.red)
                    .frame(width: 10, height: 40)
                    .offset(insertionPoint.offset)
            }
            Color.clear
                .frame(width: containerSize.width, height: containerSize.height)
                .fixedSize()
        }.onPreferenceChange(CollectionViewSizeKey.self) { value in
            withAnimation {
                self.sizes = value
            }
        }
    }

    var body: some View {
        GeometryReader { proxy in
            self.bodyHelper(containerSize: proxy.size, offsets: flowLayout(for: self.data, containerSize: proxy.size, sizes: self.sizes))
        }
    }
}

struct CollectionViewSizeKey<ID: Hashable>: PreferenceKey {
    typealias Value = [ID: CGSize]

    static var defaultValue: [ID: CGSize] { [:] }

    static func reduce(value: inout [ID: CGSize], nextValue: () -> [ID : CGSize]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct PropagateSize<V: View, ID: Hashable>: View {
    var content: V
    var id: ID
    var body: some View {
        content.background(GeometryReader { proxy in
            Color.clear.preference(key: CollectionViewSizeKey<ID>.self, value: [self.id: proxy.size])
        })
    }
}

// todo hack

extension String: Identifiable {
    public var id: String { self }
}

struct ContentView: View {
    @State var strings: [String] = (1...10).map { "Item \($0) " + String(repeating: "x", count: Int.random(in: 0...10)) }
    @State var dividerWidth: CGFloat = 0
    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .fill(.red)
                    .frame(width: dividerWidth)
                CollectionView(
                    data: strings,
                    didMove: { old, new in
                        withAnimation {
                            strings.move(fromOffsets: IndexSet(integer: old), toOffset: new)
                        }
                }) {
                    Text($0)
                        .padding(10)
                        .background(Color.gray)
                }.padding(20)
            }
            Slider(value: $dividerWidth, in: 0...500)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
