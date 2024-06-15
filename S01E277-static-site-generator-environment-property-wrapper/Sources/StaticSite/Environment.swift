//
//  File.swift
//  
//
//  Created by Chris Eidhof on 16.09.21.
//

import Foundation

struct EnvironmentValues {
    var outputDirectory: URL
    private var customValues: [ObjectIdentifier:Any] = [:]

    init(outputDirectory: URL) {
        self.outputDirectory = outputDirectory
    }
    
}

protocol EnvironmentKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

extension EnvironmentValues {
    subscript<Key: EnvironmentKey>(key: Key.Type) -> Key.Value {
        get {
            (customValues[ObjectIdentifier(key)] as? Key.Value) ?? Key.defaultValue
        }
        set {
            customValues[ObjectIdentifier(key)] = newValue
        }
    }
}

struct EnvironmentWritingModifier<Content: Rule>: Rule, BuiltinRule {
    var content: Content
    var modify: (inout EnvironmentValues) -> ()
    
    func run(environment: EnvironmentValues) throws {
        var copy = environment
        modify(&copy)
        try AnyBuiltinRule(content).run(environment: copy)
    }
}

struct EnvironmentReader<Value, Content: Rule>: Rule, BuiltinRule {
    var keyPath: KeyPath<EnvironmentValues, Value>
    var content: (Value) -> Content
    
    func run(environment: EnvironmentValues) throws {
        let value = environment[keyPath: keyPath]
        try AnyBuiltinRule(content(value)).run(environment: environment)
    }
}

extension Rule {
    func environment<Value>(_ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value) -> some Rule {
        EnvironmentWritingModifier(content: self) { env in
            env[keyPath: keyPath] = value
        }
    }
    
    func outputPath(_ path: String) -> some Rule {
        EnvironmentWritingModifier(content: self, modify: { values in
            values.outputDirectory.appendPathComponent(path)
        })
    }
}

@propertyWrapper
final class Box<A> {
    var wrappedValue: A
    init(wrappedValue: A) {
        self.wrappedValue = wrappedValue
    }
}

@propertyWrapper
struct Environment<Value>: EnvironmentSettable {
    var keyPath: KeyPath<EnvironmentValues, Value>
    @Box var values: EnvironmentValues? = nil
    
    init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
    }
    
    func set(values: EnvironmentValues) {
        self.values = values
    }
    
    var wrappedValue: Value {
        guard let env = values else { fatalError("Cannot access the environment outside the body") }
        return env[keyPath: keyPath]
    }
}

protocol EnvironmentSettable {
    func set(values: EnvironmentValues)
}

extension EnvironmentValues {
    func install<A>(on obj: A) {
        let m = Mirror(reflecting: obj)
        for child in m.children {
            if let envProperty = (child.value as? EnvironmentSettable) {
                envProperty.set(values: self)
            }
        }
    }
}

