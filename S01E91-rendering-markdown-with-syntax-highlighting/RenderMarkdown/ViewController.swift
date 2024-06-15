//
//  ViewController.swift
//  RenderMarkdown
//
//  Created by Florian Kugler on 01-03-2018.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Cocoa

protocol Block {
    static func paragraph(text: String) -> Self
    static func codeBlock(text: String, language: String?) -> Self
}


func markdown<B: Block> () -> [B] {
    return [
        B.paragraph(text: "Some paragraph text..."),
        B.codeBlock(text:
            """
            let result = 3 + 5
            print("Hello World!")
            """
        , language: "swift")
    ]
}

final class ViewController: NSViewController {
    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let strings: [Highlight<NSAttributedString>] = markdown()
        let result = strings.map { $0.rendered }.join(separator: "\n\n")
        textView.textStorage!.setAttributedString(result)
    }
}

extension Kind {
    var color: NSColor {
        switch self {
        case .keyword:
            return .red
        case .string:
            return .blue
        case .other:
            return .black
        }
    }
}

protocol HighlightedCode {
    static func highlight(text: String, tokens: [(Range<String.Index>, Kind)]) -> Self
}

struct Highlight<Result> where Result: Block & HighlightedCode {
    let rendered: Result
}

extension Highlight: Block {

    static func paragraph(text: String) -> Highlight<Result> {
        return Highlight(rendered: Result.paragraph(text: text))
    }

    static func codeBlock(text: String, language: String?) -> Highlight<Result> {
        if language == "swift" {
            let tokens: [(Range<String.Index>, Kind)] = try! highlightSyntax(code: text)
            return Highlight(rendered: Result.highlight(text: text, tokens: tokens))
        } else {
            return Highlight(rendered: Result.codeBlock(text: text, language: language))
        }
    }
}

extension NSAttributedString: HighlightedCode {

    static func highlight(text: String, tokens: [(Range<String.Index>, Kind)]) -> Self {
        let result = NSMutableAttributedString(string: text)
        for highlight in tokens {
            let range = NSRange(highlight.0, in: text)
            let color = highlight.1
            result.addAttribute(.foregroundColor, value: color, range: range)
        }
        return .init(attributedString: result)
    }
}

extension NSAttributedString: Block {

    static func paragraph(text: String) -> Self {
        return .init(string: text)
    }

    static func codeBlock(text: String, language: String?) -> Self {
        return .init(string: text)
    }


}
