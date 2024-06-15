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
                .padding(.leading)
        }
        .overlay(Color.gray.frame(width: 1), alignment: .leading)
    }
}

struct DayMidXKey: PreferenceKey {
    static var defaultValue: [Date: CGFloat] = [:]
    static func reduce(value: inout [Date : CGFloat], nextValue: () -> [Date : CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct MidXKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

extension View {
    func measureMidX(for date: Date) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: DayMidXKey.self, value: [date: proxy.frame(in: .global).midX])
        })
    }

    func measureMidX(_ onChange: @escaping (CGFloat) -> ()) -> some View {
        overlay(GeometryReader { proxy in
            Color.clear.preference(key: MidXKey.self, value: proxy.frame(in: .global).midX)
        }).onPreferenceChange(MidXKey.self) {
            onChange($0!)
        }
    }
}

struct ContentView: View {
    var model = Model.shared
    
    @State var date = Date()
    @State var scrollViewMidX: CGFloat?
    @State var visibleDays: [Date: CGFloat] = [:]
    
    var daysWithNext: [(Day, Day?)] {
        var zipped: [(Day, Day?)] = Array(zip(model.days, model.days.dropFirst()))
        if let last = model.days.last {
            zipped.append((last, nil))
        }
        return zipped
    }
    
    var centerMostDate: Date? {
        guard let midX = scrollViewMidX else { return nil }
        return visibleDays
            .mapValues { abs($0 - midX) }
            .sorted(by: { $0.value < $1.value })
            .first?.key
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
                                .background(Color.primary.opacity(day.startOfDay == centerMostDate ? 0.05 : 0))
                                .id(day.startOfDay)
                                .measureMidX(for: day.startOfDay)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo(model.days.last?.startOfDay, anchor: .center)
                    }.onChange(of: date, perform: { newValue in
                        guard newValue != centerMostDate else { return }
                        let dest = Calendar.current.startOfDay(date)
                        withAnimation {
                            proxy.scrollTo(dest, anchor: .center)
                        }
                    })
                }
            }.measureMidX {
                scrollViewMidX = $0
            }
            .onPreferenceChange(DayMidXKey.self) { dict in
                visibleDays = dict
                if let d = centerMostDate {
                    date = d
                }
            }
            DatePicker("Date", selection: $date, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .labelsHidden()
            Text("\(scrollViewMidX ?? -1)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
