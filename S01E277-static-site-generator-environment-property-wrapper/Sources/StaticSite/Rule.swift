//
//  File.swift
//  
//
//  Created by Chris Eidhof on 16.09.21.
//

import Foundation

protocol Rule {
    associatedtype Body: Rule
    @RuleBuilder var body: Body { get }
}

protocol BuiltinRule {
    func run(environment: EnvironmentValues) throws
}

extension BuiltinRule {
    var body: Never {
        fatalError()
    }
}

extension Never: Rule {
    var body: Never {
        fatalError()
    }
}

import Swim

struct Write: BuiltinRule, Rule {
    var contents: Node
    var to: String // relative path
    
    func run(environment: EnvironmentValues) throws {
        var c = contents
        for t in environment.template.reversed() {
            environment.install(on: t)
            c = t.apply(content: c)
        }
        var result = ""
        c.write(to: &result)
        let dest = environment.outputDirectory.appendingPathComponent(to)
        let dir = dest.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try result.write(to: dest, atomically: false, encoding: .utf8)
    }
}

struct AnyBuiltinRule: BuiltinRule {
    let _run: (EnvironmentValues) throws -> ()
    init<R: Rule>(_ rule: R) {
        if let builtin = rule as? BuiltinRule {
            self._run = builtin.run
        } else {
            self._run = { env in
                env.install(on: rule)
                try AnyBuiltinRule(rule.body).run(environment: env)
            }
        }
    }
    
    func run(environment: EnvironmentValues) throws {
        try _run(environment)
    }
}

extension Rule {
    func execute(outputDirectory: URL) throws {
        let env = EnvironmentValues(outputDirectory: outputDirectory)
        try AnyBuiltinRule(self).run(environment: env)
    }
}
