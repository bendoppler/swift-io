import UIKit


enum ContentElement {
    case label(String)
    case button(String, () -> ())
    case image(UIImage)
}

final class CallbackButton: UIView {
    let onTap: () -> ()
    let button: UIButton
    
    init(title: String, onTap: @escaping () -> ()) {
        self.onTap = onTap
        self.button = UIButton(type: .system)
        super.init(frame: .zero)
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.constrainEdges(to: self)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc func tapped(sender: AnyObject) {
        onTap()
    }
}

extension ContentElement {
    var view: UIView {
        switch self {
        case let .label(text):
            let label = UILabel()
            label.numberOfLines = 0
            label.text = text
            return label
            
        case let .button(title, callback):
            return CallbackButton(title: title, onTap: callback)
        case let .image(image):
            return UIImageView(image: image)
        }
    }
}

extension UIStackView {
    convenience init(elements: [ContentElement]) {
        self.init()
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        spacing = 10
        for element in elements {
            addArrangedSubview(element.view)
        }
    }
}

final class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let elements: [ContentElement] = [
            .image(UIImage(imageLiteralResourceName: "objc-logo-white.png")),
            .label("To use the Swift Talk app please login as a subscriber"),
            .button("Login with GitHub"),
            .label("If you're not registered yet, please visit http://objc.io for more information")
        ]
        
        let stack = UIStackView(elements: elements)
        view.addSubview(stack)
        stack.constrainEqual(attribute: .width, to: view)
        stack.center(in: view)
    }
}


final class StackViewController: UIViewController {
    let elements: [ContentElement]
    init(elements: [ContentElement]) {
        self.elements = elements
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let stack = UIStackView(elements: elements)
        view.addSubview(stack)
        stack.constrainEqual(attribute: .width, to: view)
        stack.center(in: view)
    }
}

let vc = ViewController()

let elements: [ContentElement] = [.image(UIImage(imageLiteralResourceName: "objc-logo-white.png")),
                                  .label("To use the Swift Talk app please login as a subscriber"),
                                  .button("Login with GitHub") {
                                        print("Button tapped")
                                  },
                                  .label("If you're not registered yet, please visit http://objc.io for more information")]

let svc = StackViewController(elements: elements)



