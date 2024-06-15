import XCTest
@testable import NotSwiftUIState

final class StateTests: XCTestCase {
    override func setUp() {
    }
    
    func testSimple() {
        struct Nested: View {
            @State var counter = 0
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }
        
        struct Sample: View {
            @State var counter = 0
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }
        
        let s = Sample()
        let node = Node()
        s.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        var nestedNode: Node {
            node.children[0].children[1]
        }
        var nestedButton: Button {
            nestedNode.children[0].view as! Button
        }
        XCTAssertEqual(button.title, "0")
        XCTAssertEqual(nestedButton.title, "0")
        
        nestedButton.action()
        node.rebuildIfNeeded()
        
        XCTAssertEqual(button.title, "0")
        XCTAssertEqual(nestedButton.title, "1")
        
        button.action()
        node.rebuildIfNeeded()

        XCTAssertEqual(button.title, "1")
        XCTAssertEqual(nestedButton.title, "1")
    }
    
    func testBindings() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }
        
        struct Sample: View {
            @State var counter = 0
            var body: some View {
                Nested(counter: $counter)
            }
        }
        
        let s = Sample()
        let node = Node()
        s.buildNodeTree(node)
        var nestedNode: Node {
            node.children[0]
        }
        var nestedButton: Button {
            nestedNode.children[0].view as! Button
        }
        XCTAssertEqual(nestedButton.title, "0")
        
        nestedButton.action()
        node.rebuildIfNeeded()
        
        XCTAssertEqual(nestedButton.title, "1")
    }
}
