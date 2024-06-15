import HTML

enum TitleKey: EnvironmentKey {
    static let defaultValue: String = "My Site"
}

extension EnvironmentValues {
    var title: String {
        get { self[TitleKey.self] }
        set { self[TitleKey.self] = newValue }
    }
}

struct Index: Rule {
    @Environment(\.title) var title: String
    var body: some Rule {
        Write(contents: h1 { "Homepage \(title)" }, to: "index.html")
    }
}

struct Archive: Rule {
    var body: some Rule {
        Write(contents: h1 { "Archive" }, to: "index.html")
    }
}

struct Blog: Rule {
    var body: some Rule {
        for post in ["one", "two", "three"] {
            Write(contents: .text(post), to: "\(post).html")
                .environment(\.title, "Blog - \(post)")
        }
    }
}

struct MySite: Rule {
    var body: some Rule {
        Index()
        Archive()
            .outputPath("archive")
        Blog()
            .outputPath("blog")
            .wrap(BlogTemplate())
    }
}

struct SiteTemplate: Template {
    @Environment(\.title) var title
    func apply(content: Node) -> Node {
        HTML.html {
            head {
                HTML.title { title }
            }
            body {
                content
            }
        }
    }
}

struct BlogTemplate: Template {
    @NodeBuilder func apply(content: Node) -> Node {
        h1 { "Blog" }
        content
    }
}

import Cocoa
import Foundation

let outputDirectory = URL(fileURLWithPath: "/Users/chris/Downloads/out")


try? FileManager.default.removeItem(at: outputDirectory)
try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)

try MySite()
    .environment(\.title, "objc.io")
    .wrap(SiteTemplate())
    .execute(outputDirectory: outputDirectory)

NSWorkspace.shared.open(outputDirectory)
