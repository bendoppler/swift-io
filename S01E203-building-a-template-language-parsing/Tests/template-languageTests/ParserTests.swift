import XCTest
import template_language

final class ParserTests: XCTestCase {

    var input: String! = nil
    var parsed: SimpleExpression {
        do {
            return try input.parse().simple
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

    override func tearDown() {
        input = nil
    }
    
    func testVariable() throws {
        for input in ["{ foo }", "{foo}"] {
            XCTAssertEqual(try input.parse().simple, .variable(name: "foo"))
        }
    }

    func testForLoop() throws {
        input = "{ for foo in bar }<p>{ foo }</p>{ end }"
        XCTAssertEqual(parsed, .`for`(variableName: "foo", collection: .variable(name: "bar"), body: [
            .tag(name: "p", body: [
                .variable(name: "foo")
            ])
        ]))
    }
    
    func testTag() throws {
        input = "<p></p>"
        XCTAssertEqual(parsed, .tag(name: "p"))
    }

    func testTagAttributes() throws {
        input = "<p name={ foo }></p>"
        XCTAssertEqual(parsed, .tag(name: "p", attributes: ["name": .variable(name: "foo")]))
    }

    func testTagBody() throws {
        input = "<p><span>{ foo }</span><div></div></p>"
        XCTAssertEqual(parsed, .tag(name: "p", body: [
            .tag(name: "span", body: [
                .variable(name: "foo")
            ]),
            .tag(name: "div")
        ]))
    }

    // MARK: - Error tags

    func testOpenTag() {
        let input = "<p>"
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expectedClosingTag("p"))
            XCTAssertEqual(parseError.offset, input.endIndex)
        }
    }

    func testMissingClosingTag() {
        let input = "<p</p>"
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expected("Attribute or >"))
            XCTAssertEqual(parseError.offset, input.range(of: "</p>")?.lowerBound)
        }
    }

    func testOpenVariable() {
        let input = "{ foo "
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expected("}"))
            XCTAssertEqual(parseError.offset, input.endIndex)
        }
    }

    func testForLoop2() throws {
        input = "{ for foo inbar }{ foo }{ end }"
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expected("in"))
            XCTAssertEqual(parseError.offset, input.range(of: "inbar")?.lowerBound)
        }
    }

    // TODO: test that identifier is not an empty string
    
    func _testSyntax() {
        _ = """
        <head><title>{ title }</title></head>
        <body>
            <ul>
                { for post in posts }
                    { if post.published }
                        <li><a href={post.url}>{ post.title }</a></li>
                    { end }
                { end }
            </ul>
        </body>
        """
    }
}
