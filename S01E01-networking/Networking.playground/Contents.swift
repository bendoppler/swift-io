//: To run this playground start a SimpleHTTPServer on the commandline like this:
//:
//: `python -m SimpleHTTPServer 8000`
//:
//: It will serve up the current directory, so make sure to be in the directory containing episodes.json

import UIKit
import XCPlayground
import PlaygroundSupport


typealias JSONDictionary = [String: AnyObject]

let url = URL(string: "http://localhost:8000/episodes.json")!

struct Episode {
    let id: String
    let title: String
}

enum HTTPMethod<Body> {
    case get
    case post(Body)
}


extension HTTPMethod {
    func map<B>(f: (Body) -> B) -> HTTPMethod<B> {
        switch self {
        case .get:
            return .get
        case .post(let body):
            return .post(f(body))
        }
    }
}

extension HTTPMethod {
    var method: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }
}

extension Episode {
    init?(dictionary: JSONDictionary) {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String else { return nil}
        self.id = id
        self.title = title
    }
}

struct Resource<A> {
    let url: URL
    let httpMethod: HTTPMethod<Data>
    let parse: (Data) -> A?
}

extension Resource {
    init(url: URL, method: HTTPMethod<Any> = .get, parseJSON: @escaping (Any) -> A?) {
        self.url = url
        self.httpMethod = method.map { json in
            try! JSONSerialization.data(withJSONObject: json, options: [])
        }
        self.parse = { data in
            
        }
    }
}

extension Episode {
    static let all =  Resource<[Episode]>(url: url, parseJSON: { json in
        let dictionaries = json as? [JSONDictionary]
        return dictionaries?.flatMap(Episode.init)
    })
    
    var media: Resource<Media> {
        let url = URL(string: "http://localhost:8000/episodes/\(id).json")!
        //TODO Return resource here
    }
}


func pushNotification(token: String) -> Resource<Bool> {
    let url = URL(string: "")!
    let dictionary = ["token": token]
    return Resource(url: url, method: .post(dictionary)) { data in
        return true
    }
}

final class WebService {
    func load<A>(resource: Resource<A>, completion: @escaping (A?) -> ()) {
        URLSession.shared.dataTask(with: resource.url) { data, _, _ in
            let result = data.flatMap(resource.parse)
            completion(result)
        }.resume()
    }
}

WebService().load(resource: Episode.all) { result in
    print(result)
}

PlaygroundPage.current.needsIndefiniteExecution = true
