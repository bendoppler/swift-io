//
//  ContentView.swift
//  VectorDrawing
//
//  Created by Chris Eidhof on 22.02.21.
//

import SwiftUI

struct PathPoint: View {
    @Binding var element: Drawing.Element

    func pathPoint(at: CGPoint) -> some View {
        let drag = DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { state in
                element.move(to: state.location)
            }
        let optionDrag = DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .modifiers(.option)
            .onChanged { state in
                element.setCoupledControlPoints(to: state.location)
            }
        let doubleClick = TapGesture(count: 2)
            .onEnded {
                element.resetControlPoints()
            }
        let gesture = doubleClick.simultaneously(with: optionDrag.exclusively(before: drag))
        return Circle()
            .stroke(Color.black)
            .background(Circle().fill(Color.white))
            .padding(2)
            .frame(width: 14, height: 14)
            .offset(x: at.x-7, y: at.y-7)
            .gesture(gesture)
    }

    func controlPoint(at: CGPoint, onDrag: @escaping (CGPoint, _ option: Bool) -> ()) -> some View {
        let drag = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { state in
                onDrag(state.location, false)
            }

        let optionDrag = DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .modifiers(.option)
            .onChanged { state in
                onDrag(state.location, true)
            }

        let gesture = optionDrag.exclusively(before: drag)
        return RoundedRectangle(cornerRadius: 2)
            .stroke(Color.black)
            .background(RoundedRectangle(cornerRadius: 2).fill(Color.white))
            .padding(4)
            .frame(width: 14, height: 14)
            .offset(x: at.x-7, y: at.y-7)
            .gesture(gesture)
    }
    
    var body: some View {
        if let cp = element.controlPoints {
            Path { p in
                p.move(to: cp.0)
                p.addLine(to: element.point)
                p.addLine(to: cp.1)
            }.stroke(Color.gray)
            controlPoint(at: cp.0) { element.moveControlPoint1(to: $0, option: $1) }
            controlPoint(at: cp.1) { element.moveControlPoint2(to: $0, option: $1) }
        }
        pathPoint(at: element.point)
    }
}

struct Points: View {
    @Binding var drawing: Drawing
    var body: some View {
        ForEach(Array(zip(drawing.elements, drawing.elements.indices)), id: \.0.id) { element in
            PathPoint(element: $drawing.elements[element.1])
        }
    }
}

struct Drawing {
    var elements: [Element] = []

    struct Element: Identifiable {
        let id = UUID()
        var point: CGPoint {
            didSet {
                point = point.rounded()
            }
        }

        var _primaryPoint: CGPoint? {
            didSet {
                _primaryPoint = _primaryPoint?.rounded()
            }
        }

        var secondaryPoint: CGPoint? {
            didSet {
                secondaryPoint = secondaryPoint?.rounded()
            }
        }

        var primaryPoint: CGPoint? {
            return _primaryPoint ?? secondaryPoint?.mirrored(relativeTo: point)
        }

        init(point: CGPoint, secondaryPoint: CGPoint?) {
            self.point = point.rounded()
            self.secondaryPoint = secondaryPoint?.rounded()
        }
    }
}

extension Drawing.Element {
    var controlPoints: (CGPoint, CGPoint)? {
        guard let s = secondaryPoint, let p = primaryPoint else { return nil }
        return (p, s)
    }

    mutating func move(to: CGPoint) {
        let diff = to - point
        point = to
        _primaryPoint = _primaryPoint.map { $0 + diff }
        secondaryPoint = secondaryPoint.map { $0 + diff }
    }

    mutating func moveControlPoint1(to: CGPoint, option: Bool) {
        if option || _primaryPoint != nil {
            _primaryPoint = to
        } else {
            secondaryPoint = to.mirrored(relativeTo: point)
        }
    }

    mutating func moveControlPoint2(to: CGPoint, option: Bool) {
        if option && _primaryPoint == nil {
            _primaryPoint = primaryPoint
        }
        secondaryPoint = to
    }

    mutating func resetControlPoints() {
        _primaryPoint = nil
        secondaryPoint = nil
    }

    mutating func setCoupledControlPoints(to: CGPoint) {
        _primaryPoint = nil
        secondaryPoint = to
    }
}

extension Drawing {
    var path: Path {
        var result = Path()
        guard let f = elements.first else { return result }
        result.move(to: f.point)
        var previousControlPoint: CGPoint?
        for element in elements.dropFirst() {
            if let previousCP = previousControlPoint {
                let cp2 = element.controlPoints?.0 ?? element.point
                result.addCurve(to: element.point, control1: previousCP, control2: cp2)
            } else {
                if let mirrored = element.controlPoints?.0 {
                    result.addQuadCurve(to: element.point, control: mirrored)
                } else {
                    result.addLine(to: element.point)
                }
            }
            previousControlPoint = element.secondaryPoint
        }
        return result
    }
}

extension Drawing {
    mutating func update(for state: DragGesture.Value) {
        let isDrag = state.startLocation.distance(to: state.location) > 1
        elements.append(Element(point: state.startLocation, secondaryPoint: isDrag ? state.location : nil))
    }
}

struct DrawingView: View {
    @Binding var drawing: Drawing
    @GestureState var currentDrag: DragGesture.Value? = nil

    var liveDrawing: Drawing {
        var copy = drawing
        if let state = currentDrag {
            copy.update(for: state)
        }
        return copy
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.white
            liveDrawing.path.stroke(Color.black, lineWidth: 2)
            Points(drawing: Binding(get: { liveDrawing }, set: { drawing = $0 }))
        }.gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .updating($currentDrag, body: { value, state, _ in
                    state = value
                })
                .onEnded { state in
                    drawing.update(for: state)
                }
        )
    }
}

struct ContentView: View {
    @State var drawing = Drawing()
    var body: some View {
        VStack {
            DrawingView(drawing: $drawing)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ScrollView {
                Text(drawing.path.code)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(height: 150)
        }
    }
}

extension CGPoint {
    var code: String {
        return "CGPoint(x: \(x), y: \(y))"
    }
}

extension Path.Element {
    var code: String {
        switch self {
        case .move(to: let to):
            return "p.move(to: \(to.code))"
        case .line(to: let to):
            return "p.addLine(to: \(to.code))"
        case .quadCurve(to: let to, control: let control):
            return "p.addQuadCurve(to: \(to.code), control: \(control.code))"
        case .curve(to: let to, control1: let control1, control2: let control2):
            return "p.addCurve(to: \(to.code), control1: \(control1.code), control2: \(control2.code)"
        case .closeSubpath:
            return "p.closeSubpath()"
        }
    }
}

extension Path {
    var code: String {
        guard !isEmpty else { return "Path()" }
        var result = "Path { p in \n"
        forEach { el in
            result.append("     \(el.code)\n")
        }
        result.append("}")
        return result
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
