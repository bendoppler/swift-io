struct Person: Equatable {
    var first: String
    var last: String
}

var people = [
    Person(first: "Jo", last: "Smith"),
    Person(first: "Joanne", last: "Williams"),
    Person(first: "Annie", last: "Williams"),
    Person(first: "Robert", last: "Jones")
] {
    didSet {
        dump("people didSet \(people)")
    }
}

final class Var<A> {

    private let _get: () -> A
    private let _set: (A) -> ()
    let addObserver: (_ observer: @escaping Observer) -> Disposable

    var value: A {
        get {
            return _get()
        }
        set {
            _set(newValue)
        }
    }

    init(initialValue: A) {
        var observers: [Int: Observer] = [:]
        var value: A = initialValue {
            didSet {
                for o in observers.values {
                    o(value, oldValue)
                }
            }
        }
        _get = { value }
        _set = { newValue in value = newValue }
        var freshInt = (0...).makeIterator()
        addObserver = { observer in
            let id = freshInt.next()!
            observers[id] = observer
            return Disposable {
                observers[id] = nil
            }
        }
    }

    typealias Observer = (A, A) -> ()

    fileprivate init(get: @escaping () -> A, set: @escaping (A) -> (), addObserver: @escaping (@escaping Observer) -> Disposable) {
        _get = get
        _set = set
        self.addObserver = addObserver
    }

    subscript<B>(keyPath: WritableKeyPath<A, B>) -> Var<B> {
        return Var<B>(get: {
            self.value[keyPath: keyPath]
        }, set: { newValue in
            self.value[keyPath: keyPath] = newValue
        }, addObserver: { observer in
            self.addObserver { newValue, oldValue in
                observer(newValue[keyPath: keyPath], oldValue[keyPath: keyPath])
            }
        })
    }
}

final class Disposable {
    private let dispose: () -> ()

    init(_ dispose: @escaping () -> ()) {
        self.dispose = dispose
    }

    deinit {
        dispose()
    }
}

extension Var where A: MutableCollection {
    subscript(index: A.Index) -> Var<A.Element> {
        return Var<A.Element>(get: {
            self.value[index]
        }, set: { newValue in
            self.value[index] = newValue
        }, addObserver: { observer in
            self.addObserver { newValue, oldValue in
                observer(newValue[index], oldValue[index] )
            }
        })
    }
}

let personVar: Var<Person> = Var(initialValue: people[0])


let firstNameVar: Var<String> = personVar[\.first]

firstNameVar.value = "test"
//personVar.value.first = "new first name"

//dump(firstNameVar.value)
dump(personVar.value)

let peopleVar: Var<[Person]> = Var(initialValue: people)

//peopleVar.addObserver { p, oldPeople in
//    print("people changed: \(p)")
//}

let personVar2: Var<Person> = peopleVar[0]

//personVar2.value.first = "new"

final class PersonViewController {
    let person: Var<Person>
    var disposable: Any?

    init(person: Var<Person>) {
        self.person = person
        disposable = self.person.addObserver { [weak self] (newPerson, oldPerson) in
            guard newPerson != oldPerson else { return }
            print(newPerson)
        }
    }

    func update() {
        person.value.last = "changed"
    }
}

let vc = PersonViewController(person: peopleVar[0])
vc.update()
peopleVar[1].value.first = "Test"


