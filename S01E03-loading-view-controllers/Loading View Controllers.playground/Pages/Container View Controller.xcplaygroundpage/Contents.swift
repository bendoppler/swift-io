//: To run this playground start a SimpleHTTPServer on the commandline like this:
//:
//: `python -m SimpleHTTPServer 8000`
//:
//: It will serve up the current directory, so make sure to be in the directory containing episode.json

import UIKit
import PlaygroundSupport

let url = URL(string: "http://localhost:8000/episode.json")!
let episodeResource = Resource<Episode>(url: url) { any in
    (any as? JSONDictionary).flatMap(Episode.init)
}

protocol Loading {
    associatedtype ResourceType
    var spinner: UIActivityIndicatorView { get }
    func configure(value: ResourceType)
}

extension Loading where Self: UIViewController {
    func load(resource: Resource<ResourceType>) {
        spinner.startAnimating()
        sharedWebservice.load(resource: resource) { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else {
                return
            }
            self?.configure(value: value)
        }
    }
}

final class LoadingViewController: UIViewController {
    let spinner = UIActivityIndicatorView(style: .gray)
    init<A>(load: ( @escaping (Result<A>) -> ()) -> (), build: @escaping (A) -> UIViewController) {
        super.init(nibName: nil, bundle: nil)
        spinner.startAnimating()
        load() { [weak self] result in
            self?.spinner.stopAnimating()
            guard let value = result.value else {
                return
            }
            let viewController = build(value)
            self?.add(content: viewController)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)
        spinner.center(inView: self.view)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func add(content: UIViewController) {
        addChild(content)
        view.addSubview(content.view)
        content.view.translatesAutoresizingMaskIntoConstraints = false
        content.view.constrainEdges(toMarginOf: view)
        content.didMove(toParent: self)
    }
}


final class EpisodeDetailViewController: UIViewController {
    let titleLabel = UILabel()
    
    convenience init(episode: Episode) {
        self.init()
        titleLabel.text = episode.title
    }
    
    override func viewDidLoad() {
        view.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.constrainEdges(toMarginOf: view)
    }
}


let sharedWebservice = Webservice()

let episodesVC = LoadingViewController(load: { callback in
    sharedWebservice.load(resource: episodeResource, completion: callback)
}, build: EpisodeDetailViewController.init)

episodesVC.view.frame = CGRect(x: 0, y: 0, width: 250, height: 300)


PlaygroundPage.current.liveView = episodesVC
