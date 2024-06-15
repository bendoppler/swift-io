protocol View {
    associatedtype Body: View
    var body: Body { get }
}

protocol BuiltinView {
    func _buildNodeTree(_ node: Node)
}

extension View {
    func observeObjects(_ node: Node) {
        let m = Mirror(reflecting: self)
        for child in m.children {
            guard let observedObject = child.value as? AnyObservedObject else { return }
            observedObject.addDependency(node)
        }
    }
    
    func buildNodeTree(_ node: Node) {
        if let b = self as? BuiltinView {
            node.view = b
            b._buildNodeTree(node)
            return
        }
        node.view = AnyBuiltinView(self)
        
        // check if we actually need to execute the body
        
        self.observeObjects(node)
        
        let b = body
        if node.children.isEmpty {
            node.children = [Node()]
        }
        b.buildNodeTree(node.children[0])
        node.needsRebuild = false
    }
}

extension Never: View {
    var body: Never {
        fatalError("We should never reach this")
    }
}

extension BuiltinView {
    var body: Never {
        fatalError("This should never happen")
    }
}

struct Button: View, BuiltinView {
    var title: String
    var action: () -> ()
    init(_ title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }
    
    func _buildNodeTree(_ node: Node) {
        // todo create a UIButton
    }
}
