//
//  SourceKitHighlight.swift
//  RenderMarkdown
//
//  Created by Chris Eidhof on 30.01.18.
//  Copyright © 2018 objc.io. All rights reserved.
//

import Cocoa

enum Kind: Int {
    case keyword
    case string
    case other
    
    init?(sourceKitType type: String) {
        switch type {
        case "source.lang.swift.syntaxtype.keyword": self = .keyword
        case "source.lang.swift.syntaxtype.string": self = .string
        default: self = .other
        }
    }
}

func highlightSyntax(code: String) throws -> [(Range<String.Index>, Kind)] {
    let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory())
    let tmpFile = tempDir.appendingPathComponent(UUID().uuidString + ".swift")!
    try! code.write(to: tmpFile, atomically: true, encoding: .utf8)
    let data = Process.execute(path: "/usr/local/bin/sourcekitten", arguments: ["syntax", "--file", tmpFile.path])
    let objs = try! JSONSerialization.jsonObject(with: data, options: [])
    return (objs as! [[String:Any]]).map { dict in
        let offset = dict["offset"] as! Int
        let length = dict["length"] as! Int
        let offsetStart = code.utf8.index(code.startIndex, offsetBy: offset)
        let offsetEnd = code.utf8.index(offsetStart, offsetBy: length)
        let range = offsetStart..<offsetEnd
        return (range, Kind(sourceKitType: dict["type"] as! String)!)
    }
}

extension Process {
    static func execute(path: String, arguments: [String]) -> Data {
        let pipe = Pipe()
        let file = pipe.fileHandleForReading
        defer { file.closeFile() }
        let task = Process()
        task.launchPath = path
        task.arguments = arguments
        task.standardOutput = pipe
        task.launch()
        let data = file.readDataToEndOfFile()
        return data
    }
}


