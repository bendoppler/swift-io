import Foundation
import PlaygroundSupport

let center = NotificationCenter.default

protocol NotificationDescriptor {
    static var name: Notification.Name { get }
    init(notification: Notification)
}

struct PlaygroundPageNotification {
    let page: PlaygroundPage
    let needsIndefiniteExecution: Bool
}

extension PlaygroundPageNotification: NotificationDescriptor {
    static let name = Notification.Name("PlaygroundPageNeedsIndefiniteExecutionDidChangeNotification")
    init(notification note: Notification) {
        page = note.object as! PlaygroundPage
        needsIndefiniteExecution = note.userInfo?["PlaygroundPageNeedsIndefiniteExecution"] as! Bool
    }
}

extension NotificationCenter {
    func addObserver<Note: NotificationDescriptor>(queue: OperationQueue? = nil, using block: @escaping (Note) -> ()) -> Token {
        let token = addObserver(forName: Note.name,
                           object: nil,
                           queue: queue) { note in
            block(Note(notification: note))
        }
        return Token(token: token, center: self)
    }
}

class Token {
    let token: NSObjectProtocol
    let center: NotificationCenter
    
    init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }
    
    deinit {
        center.removeObserver(token)
    }
}

var token: Token? = center.addObserver { (note: PlaygroundPageNotification) in print(note) }

PlaygroundPage.current.needsIndefiniteExecution = true
PlaygroundPage.current.needsIndefiniteExecution = false

token = nil

PlaygroundPage.current.needsIndefiniteExecution = true

