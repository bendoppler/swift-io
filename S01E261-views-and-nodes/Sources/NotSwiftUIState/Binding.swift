//
//  File.swift
//  
//
//  Created by Do Thai Bao on 16/03/2023.
//

import Foundation

@propertyWrapper
struct Binding<Value>: Equatable {
    var get: () -> Value
    var set: (Value) -> ()
    private let id = UUID()

    public var wrappedValue: Value {
        get { get() }
        nonmutating set { set(newValue) }
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
