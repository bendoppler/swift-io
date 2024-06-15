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
    var body: some Rule {
        EnvironmentReader(keyPath: \.title) { title in
            Write(contents: html {
                HTML.body {
                    h1 { title }
                }
            }, to: "index.html")

        }
    }
}

struct MySite: Rule {
    var body: some Rule {
        Index()
            .environment(\.title, "objc.io")
    }
}

import Cocoa
import Foundation

let outputDirectory = URL(fileURLWithPath: "/Users/chris/Downloads/out")


try? FileManager.default.removeItem(at: outputDirectory)
try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true, attributes: nil)

try MySite().execute(outputDirectory: outputDirectory)

NSWorkspace.shared.open(outputDirectory)
