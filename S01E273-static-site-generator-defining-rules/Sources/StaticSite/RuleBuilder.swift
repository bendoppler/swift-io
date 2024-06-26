//
//  File.swift
//  
//
//  Created by Do Thai Bao on 25/03/2023.
//

import Foundation

@resultBuilder
enum RuleBuilder {}

struct Pair<A, B> {
    var left: A
    var right: B

    init(_ left: A, _ right: B) {
        self.left = left
        self.right = right
    }
}

extension Pair: BuiltinRule, Rule where A: Rule, B: Rule {
    func run(environment: EnvironmentValues) throws {
        try AnyBuiltinRule(left).run(environment: environment)
        try AnyBuiltinRule(right).run(environment: environment)
    }
}

extension RuleBuilder {
    static func buildBlock(_ r0: Never) -> Never {
    }

    static func buildBlock<R0: Rule>(_ r0: R0) -> some Rule {
        r0
    }

    static func buildBlock<R0: Rule, R1: Rule>(_ r0: R0, _ r1: R1) -> some Rule {
        Pair(r0, r1)
    }

    static func buildBlock<R0: Rule, R1: Rule, R2: Rule>(_ r0: R0, _ r1: R1, _ r2: R2) -> some Rule {
        Pair(r0, Pair(r1, r2))
    }

    static func buildArray<R: Rule>(_ rules: [R]) -> some Rule {
        rules
    }
}

extension Array: BuiltinRule, Rule where Element: Rule {
    func run(environment: EnvironmentValues) throws {
        for rule in self {
            try AnyBuiltinRule(rule).run(environment: environment)
        }
    }

    var body: Never {
        fatalError()
    }
}
