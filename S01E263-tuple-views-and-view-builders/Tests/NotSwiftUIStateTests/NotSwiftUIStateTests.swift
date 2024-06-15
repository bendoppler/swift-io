import XCTest
@testable import NotSwiftUIState
import Combine

final class Model: ObservableObject {
    @Published var counter: Int = 0
}

extension View {
    func debug(_ f: () -> ()) -> some View {
        f()
        return self
    }
}

var nestedBodyCount = 0
var contentViewBodyCount = 0


struct ContentView: View {
    @ObservedObject var model = Model()
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
    }
}

final class NotSwiftUIStateTests: XCTestCase {
    override func setUp() {
        nestedBodyCount = 0
        contentViewBodyCount = 0
    }
    func testUpdate() {
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].view as! Button
        }
        XCTAssertEqual(button.title, "0")
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(button.title, "1")
    }
    
    func testConstantNested() {
        struct Nested: View {
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested()
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        XCTAssertEqual(contentViewBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentViewBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 1)
    }
    
    func testChangedNested() {
        struct Nested: View {
            var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }
        
        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        XCTAssertEqual(contentViewBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentViewBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 2)
    }

}
