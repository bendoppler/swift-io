import Combine

protocol AnyObservedObject {
    func addDependency(_ node: Node)
}

@propertyWrapper
struct ObservedObject<ObjectType: ObservableObject>: AnyObservedObject {
    private var box: ObservedObjectBox<ObjectType>
    
    init(wrappedValue: ObjectType) {
        box = ObservedObjectBox(wrappedValue)
    }
    
    var wrappedValue: ObjectType {
        box.object
    }
    
    func addDependency(_ node: Node) {
        box.addDependency(node)
    }
}

fileprivate final class ObservedObjectBox<ObjectType: ObservableObject> {
    var object: ObjectType
    var cancellable: AnyCancellable?
    weak var node: Node?
    
    init(_ object: ObjectType) {
        self.object = object
    }
    
    func addDependency(_ node: Node) {
        if node === self.node { return }
        self.node = node
        cancellable = object.objectWillChange.sink { _ in
            node.needsRebuild = true
        }
    }
}
