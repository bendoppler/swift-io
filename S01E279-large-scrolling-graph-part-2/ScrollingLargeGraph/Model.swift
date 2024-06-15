//
//  Model.swift.swift
//  LargeGraph
//
//  Created by Florian Kugler on 05-10-2021.
//

import Foundation
import SwiftUI

struct DataPoint: Identifiable {
    var id = UUID()
    var date: Date
    var value: Double // between 0...1
    
    func point(in day: Day) -> UnitPoint {
        let x = date.timeIntervalSince(day.startOfDay) / (24 * 60 * 60)
        let y = (1-value)
        return UnitPoint(x: x, y: y)
    }
}

struct Day: Identifiable {
    var values: [DataPoint]
    var startOfDay: Date
    
    var id: Date { startOfDay }
}

extension Calendar {
    func startOfDay(_ date: Date) -> Date {
        var comps = dateComponents([.year, .month, .day], from: date)
        comps.timeZone = .init(secondsFromGMT: 0)
        return self.date(from: comps)!
    }
}

final class Model {
    var days: [Day] = []
    
    static let shared = Model()
    
    init() {
        generateRandomValues()
    }
    
    func generateRandomValues() {
        var lastDate = Date()
        let values: [DataPoint] = (0..<100_000).map { x in
            let randomInterval = 60 * 60 * Double.random(in: 0.5...3)
            lastDate.addTimeInterval(-randomInterval)
            return DataPoint(date: lastDate, value: Double.random(in: 0...1))
        }.reversed()
        
        // Group the events by date
        var current = Calendar.current.startOfDay(values[0].date)
        var next: Date { current.addingTimeInterval(3600*24)}
        var dayValues: [DataPoint] = []
        for value in values {
            if value.date >= next {
                days.append(Day(values: dayValues, startOfDay: current))
                dayValues = []
                current = next
            }
            dayValues.append(value)
        }
        if !dayValues.isEmpty {
            days.append(Day(values: dayValues, startOfDay: current))
        }
    }
    
    func firstPointOfNextDay(_ day: Day) -> DataPoint? {
        guard let ix = days.firstIndex(where: { $0.id == day.id }), ix + 1 < days.endIndex else {
            return nil
        }
        
        return days[ix+1].values.first
    }
}
