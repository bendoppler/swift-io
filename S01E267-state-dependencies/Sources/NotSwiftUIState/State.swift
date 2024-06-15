//
//  File.swift
//  
//
//  Created by Chris Eidhof on 24.06.21.
//

import Foundation

protocol StateProperty {
    var value: Any { get nonmutating set }
}

@propertyWrapper
struct State<Value>: StateProperty {
    private var box: Box<StateBox<Value>>
    
    init(wrappedValue: Value) {
        self.box = Box(StateBox(wrappedValue))
    }
    
    var wrappedValue: Value {
        get { box.value.value }
        nonmutating set { box.value.value = newValue }
    }
    
    var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
    
    var value: Any {
        get { box.value }
        nonmutating set { box.value = newValue as! StateBox<Value> }
    }
}

final class Box<Value> {
    var value: Value
    init(_ value: Value) {
        self.value = value
    }
}

var currentGlobalBodyNode: Node? = nil

final class StateBox<Value> {
    private var _value: Value
    private var dependencies: [Weak<Node>] = []
    
    init(_ value: Value) {
        self._value = value
    }
    
    var value: Value {
        get {
            dependencies.append(Weak(currentGlobalBodyNode!))
            // skip duplicates and remove nil entries?
            return _value
        }
        set {
            _value = newValue
            for d in dependencies {
                d.value?.needsRebuild = true
            }
        }
    }
}

final class Weak<A: AnyObject> {
    weak var value: A?
    init(_ value: A) {
        self.value = value
    }
}
