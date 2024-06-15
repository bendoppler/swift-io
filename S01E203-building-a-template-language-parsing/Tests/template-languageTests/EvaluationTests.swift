//
//  File.swift
//  
//
//  Created by Do Thai Bao on 04/11/2022.
//

import XCTest
import template_language

final class EvaluationTests: XCTestCase {

    var input: String! = nil
    var parsed: AnnotatedExpression {
        do {
            return try input.parse()
        } catch {
            let p = error as! ParseError
            let lineRange = input.lineRange(for: p.offset..<p.offset)
            print(input[lineRange])
            let dist = input.distance(from: lineRange.lowerBound, to: p.offset)
            print(String(repeating: " ", count: dist) + "^")
            print(p.reason)
            fatalError()
        }
    }

    var context: EvaluationContext =  EvaluationContext()

    var evaluated: TemplateValue {
        do {
            return try context.evaluate(parsed)
        } catch {
            dump(error)
            fatalError()
        }
    }

    override func tearDown() {
        input = nil
        context = EvaluationContext()
    }

    func testVariable() throws {
        input = "{ title }"
        context = EvaluationContext(values: ["title": .string("Title")])
        XCTAssertEqual(evaluated, .string("Title"))
    }

    func testForLoop() {
        input = "{ for foo in bar }<p>{ foo }</p>{ end }"
        context = EvaluationContext(values: ["bar": .array([.string("Hello"), .string("world")])])
        XCTAssertEqual(evaluated, .rawHTML("<p>Hello</p><p>world</p>"))
    }

    func testTag() throws {
        input = "<p><span>{bar}</span>{ title }</p>"
        context = EvaluationContext(values: ["title": .string("Title & Foo"), "bar": .string("&")])
        XCTAssertEqual(evaluated, .rawHTML("<p><span>&amp;</span>Title &amp; Foo</p>"))
    }

    func testTagWithAttributes() throws {
        input = "<div id={name}></div>"
        context = EvaluationContext(values: ["name": .string("foo \" bar")])
        XCTAssertEqual(evaluated, .rawHTML("<div id=\"foo &quot; bar\"></div>"))
    }

    func testNonExistentVariable() throws {
        input = "<p>{ title }</p>"
        XCTAssertThrowsError(try context.evaluate(parsed)) { err in
            let e = err as! EvaluationError
            XCTAssertEqual(e.reason, .variableMissing("title"))
            XCTAssertEqual(e.range, input.range(of: "title"))
        }
    }

    func testForLoopWithNonArray() {
        input = "{ for foo in bar }{ foo }{ end }"
        context = EvaluationContext(values: ["bar": .string("Hello")])
        XCTAssertThrowsError(try context.evaluate(parsed)) { err in
            let e = err as! EvaluationError
            XCTAssertEqual(e.reason, .expectedArray)
            XCTAssertEqual(e.range, input.range(of: "bar"))
        }
    }

    func testEvaluatingNonStringConvertibleToHTML() {
        input = "<p>{ foo }</p>"
        context = EvaluationContext(values: ["foo": .array([.string("Hello")])])
        XCTAssertThrowsError(try context.evaluate(parsed)) { err in
            let e = err as! EvaluationError
            XCTAssertEqual(e.reason, .expectedHTMLConvertible)
            XCTAssertEqual(e.range, input.range(of: "foo"))
        }
    }
}
