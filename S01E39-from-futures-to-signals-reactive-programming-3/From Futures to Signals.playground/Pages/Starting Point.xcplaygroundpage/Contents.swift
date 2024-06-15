import Cocoa

enum Result<A> {
    case success(A)
    case error(Error)
    
    init(_ value: A?, or error: Error) {
        if let value = value {
            self = .success(value)
        } else {
            self = .error(error)
        }
    }
}

final class KeyValueObserver<A>: NSObject {
    let block: (A) -> ()
    let keyPath: String
    var object: NSObject
    init(object: NSObject, keyPath: String, _ block: @escaping (A) -> ()) {
        self.block = block
        self.keyPath = keyPath
        self.object = object
        super.init()
        object.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
    }
    
    deinit {
        object.removeObserver(self, forKeyPath: keyPath)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        block(change![.newKey] as! A)
    }
}


extension Result {
    func map<B>(_ transform: (A) -> B) -> Result<B> {
        switch self {
        case .success(let value): return .success(transform(value))
        case .error(let error): return .error(error)
        }
    }
}

extension String: Error { }

final class Atomic<A> {
    private var queue = DispatchQueue(label: "serial queue")
    private var _value: A
    
    init(_ value: A) {
        self._value = value
    }
    
    var value: A {
        get {
            queue.sync {
                return self._value
            }
        }
        
        set {
            queue.sync {
                self._value =  newValue
            }
        }
    }
}

final class Signal<A> {
    private typealias Token = UUID
    private typealias Callbacks = [Token: (Result<A>) -> ()]
    private var callbacks: Atomic<Callbacks> = Atomic([:])
    private var objects: Atomic<[Any]> = Atomic([])
    
    static func pipe() -> ((Result<A>) -> (), Signal<A>) {
        let signal = Signal<A>()
        return ({ [weak signal] value in signal?.send(value) }, signal)
    }
    
    private func send(_ value: Result<A>) {
        for callback in callbacks.value.values {
            callback(value)
        }
    }
    
    func subscribe(callback: @escaping (Result<A>) -> ()) -> Disposable {
        let token = UUID()
        callbacks.value[token] = callback
        
        return Disposable {
            self.callbacks.value[token] = nil
        }
    }
    
    func keepAlive(_ object: Any) {
        objects.value.append(object)
    }
    
    func map<B>(_ transform: @escaping (A) -> B) -> Signal<B> {
        let (sink, signal) = Signal<B>.pipe()
        let disposable = subscribe { result in
            sink(result.map(transform))
        }
        signal.keepAlive(disposable)
        return signal
    }
    
    deinit {
        print("Removing signal")
    }
}

final class Disposable {
    let dispose: () -> ()
    init(dispose: @escaping () -> ()) {
        self.dispose = dispose
    }
    
    deinit {
        dispose()
    }
}

extension NSTextField {
    func signal() -> Signal<String> {
        let (sink, result) = Signal<String>.pipe()
        let observer = KeyValueObserver(object: self, keyPath: #keyPath(stringValue)) { str in
            sink(.success(str))
        }
        result.keepAlive(observer)
        return result
    }
}

final class VC {
    let textField = NSTextField()
    var disposables: [Disposable] = []
    func viewDidLoad() {
        let intSignal = textField.signal().map { Int($0) }
        let disposable = intSignal.subscribe { result in
            print(result)
        }
        disposables.append(disposable)
        let disposable2 = intSignal.subscribe { result in
            print("hello: \(result)")
        }
        disposables.append(disposable2)
    }
    
    deinit {
        print("Removing vc")
    }
}

var vc: VC? = VC()
vc?.viewDidLoad()
vc?.textField.stringValue = "1"
vc = nil
