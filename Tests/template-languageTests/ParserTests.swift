import XCTest
import template_language

final class ParserTests: XCTestCase {
    var input: String! = nil
    var parsed: Expression {
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
    
    override func tearDown() {
        input = nil
    }
    
    func testVariable() throws {
        for input in ["{ foo }", "{foo}"] {
            XCTAssertEqual(try input.parse(), .variable(name: "foo"))
        }
    }
    
    func testTag() throws {
        let input = "<p></p>"
        XCTAssertEqual(try input.parse(), .tag(name: "p"))
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
    
    // MARK: Error Tests

    func testOpenVariable() {
        let input = "{ foo "
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expected("}"))
            XCTAssertEqual(parseError.offset, input.endIndex)
        }
    }

    func testOpenTag() {
        let input = "<p>"
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expectedClosingTag("p"))
            XCTAssertEqual(parseError.offset, input.endIndex)
        }
    }
    
    func testMissingClosingAngleBracket() {
        let input = "<p</p>"
        XCTAssertThrowsError(try input.parse()) { err in
            let parseError = err as! ParseError
            XCTAssertEqual(parseError.reason, .expected(">"))
            XCTAssertEqual(parseError.offset, input.range(of: "</p>")!.lowerBound)
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
