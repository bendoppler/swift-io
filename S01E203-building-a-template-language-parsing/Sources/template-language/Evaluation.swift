//
//  File.swift
//  
//
//  Created by Do Thai Bao on 04/11/2022.
//

import Foundation

public enum TemplateValue: Hashable {
    case string(String)
    case rawHTML(String)
    case array([TemplateValue])
}

public struct EvaluationContext {
    public init(values: [String : TemplateValue] = [:]) {
        self.values = values
    }
    public var values: [String: TemplateValue]
}

public struct EvaluationError: Error, Hashable {
    public var range: Range<String.Index>
    public var reason: Reason

    public enum Reason: Hashable {
        case variableMissing(String)
        case expectedString
        case expectedHTMLConvertible
        case expectedArray
    }
}

extension TemplateValue {
    func toHTMLString(range: Range<String.Index>) throws -> String {
        switch self {
        case .string(let str):
            return str.escaped
        case .rawHTML(let html):
            return html
        case .array: throw EvaluationError(range: range, reason: .expectedHTMLConvertible)
        }
    }
}

extension EvaluationContext {
    public func evaluate(_ expr: AnnotatedExpression) throws -> TemplateValue {
        switch expr.expression {
        case .variable(let name):
            guard let value = values[name] else {
                throw EvaluationError(range: expr.range, reason: .variableMissing(name))
            }
            return value
        case .tag(let name, let attributes, let body):
            let bodyString = try body.map { expr in
                return try self.evaluate(expr).toHTMLString(range: expr.range)
            }.joined()
            let attText = try attributes.isEmpty ? "" : " " + attributes.map { (key, value) in
                guard case let .string(valueText) = try evaluate(value) else {
                    throw EvaluationError(range: value.range, reason: .expectedString)
                }
                return "\(key)=\"\(valueText.attributeEscaped)\""
            }.joined(separator: " ")
            let result = "<\(name)\(attText)>\(bodyString)</\(name)>"
            return .rawHTML(result)
        case .for(variableName: let variableName, collection: let collection, body: let body):
            var result: String = ""
            guard case let .array(coll) = try evaluate(collection) else {
                throw EvaluationError(range: collection.range, reason: .expectedArray)
            }
            for el in coll {
                var childContext = self
                childContext.values[variableName] = el
                for b in body {
                    result += try childContext.evaluate(b).toHTMLString(range: b.range)
                }
            }
            return .rawHTML(result)
        }
    }
}

extension String {
    // todo verify that this is secure
    var escaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    var attributeEscaped: String {
        self
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
