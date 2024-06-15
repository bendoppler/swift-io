//
//  ContentView.swift
//  ScrollingLargeGraph
//
//  Created by Chris Eidhof on 26.10.21.
//

import SwiftUI

func *(lhs: UnitPoint, rhs: CGSize) -> CGPoint {
    CGPoint(x: lhs.x * rhs.width, y: lhs.y * rhs.height)
}

func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

struct Line: Shape {
    var from: UnitPoint
    var to: UnitPoint
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: rect.origin + from * rect.size)
            p.addLine(to: rect.origin + to * rect.size)
        }
    }
}

struct DayView: View {
    var day: Day
    var firstPointOfNextDay: DataPoint?
    
    var pointsWithNext: [(DataPoint, DataPoint)] {
        var zipped = Array(zip(day.values, day.values.dropFirst()))
        if let l = day.values.last, let f = firstPointOfNextDay {
            zipped.append((l, f))
        }
        return zipped
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    ForEach(pointsWithNext, id: \.0.id) { (value, next) in
                        Line(from: value.point(in: day), to: next.point(in: day))
                            .stroke(lineWidth: 1)
                    }
                    ForEach(day.values) { dataPoint in
                        let point = dataPoint.point(in: day)
                        Circle()
                            .frame(width: 5, height: 5)
                            .offset(x: -2.5, y: -2.5)
                            .offset(x: point.x * proxy.size.width, y: point.y * proxy.size.height)
                    }
                }
            }
            Text(day.startOfDay, style: .date)
        }
    }
}

struct ContentView: View {
    var model = Model.shared
    
    @State var date = Date()
    
    var daysWithNext: [(Day, Day?)] {
        var zipped: [(Day, Day?)] = Array(zip(model.days, model.days.dropFirst()))
        if let last = model.days.last {
            zipped.append((last, nil))
        }
        return zipped
    }
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                ScrollViewReader { proxy in
                    LazyHStack(spacing: 0) {
                        let zipped = daysWithNext
                        ForEach(zipped, id: \.0.id) { (day, nextDay) in
                            DayView(day: day, firstPointOfNextDay: nextDay?.values.first)
                                .frame(width: 300)
                                .border(Color.blue)
                                .id(day.startOfDay)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(model.days.last?.startOfDay, anchor: .center)
                    }.onChange(of: date, perform: { newValue in
                        let dest = Calendar.current.startOfDay(date)
                        withAnimation {
                            proxy.scrollTo(dest, anchor: .center)
                        }
                    })
                }
            }
            DatePicker("Date", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
