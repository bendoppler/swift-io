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

struct ContentView: View {
    @ObservedObject var model = Model()
    var body: some View {
        Button("\(model.counter)") {
            model.counter += 1
        }
    }
}

let nestedModel = Model()
fileprivate var nestedBodyCount = 0
fileprivate var contentBodyCount = 0

final class NotSwiftUIStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        nestedBodyCount = 0
        contentBodyCount = 0
        nestedModel.counter = 0
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
                return Button("Nested button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested().debug { contentBodyCount += 1 }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 1)
    }

    func testChangedNested() {
        struct Nested: View {
            var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: model.counter).debug {
                    contentBodyCount += 1
                }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 2)
    }

    func testUnchangedNested() {
        struct Nested: View {
            var isLarge: Bool = false
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(isLarge: model.counter > 10).debug {
                    contentBodyCount += 1
                }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 1)
    }

    func testUnchangedNestedWithObservedObject() {
        struct Nested: View {
            @ObservedObject var model = nestedModel
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested().debug {
                    contentBodyCount += 1
                }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 1)
    }

    func testBinding1() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested button", action: {})
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: $model.counter).debug {
                    contentBodyCount += 1
                }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 2)
    }

    func testBinding2() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("\(counter)", action: { counter += 1 })
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Nested(counter: $model.counter).debug {
                    contentBodyCount += 1
                }
            }
        }

        let v = ContentView()
        let node = Node()
        v.buildNodeTree(node)
        var button: Button {
            node.children[0].children[0].view as! Button
        }
        XCTAssertEqual(contentBodyCount, 1)
        XCTAssertEqual(nestedBodyCount, 1)
        XCTAssertEqual(button.title, "0")
        button.action()
        node.rebuildIfNeeded()
        XCTAssertEqual(contentBodyCount, 2)
        XCTAssertEqual(nestedBodyCount, 2)
        XCTAssertEqual(button.title, "1")
    }
}
