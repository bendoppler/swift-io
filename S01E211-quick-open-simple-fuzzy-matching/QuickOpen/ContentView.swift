import SwiftUI
import Cocoa
import OSLog

let log = OSLog(subsystem: "objc.io", category: "FuzzyMatch")

let linuxFiles = try! String(contentsOf: Bundle.main.url(forResource: "linux", withExtension: "txt")!).split(separator: "\n")

public let files = linuxFiles

public struct Matrix<A> {
    var array: [A]
    let width: Int
    private(set) var height: Int
    init(width: Int, height: Int, initialValue: A) {
        array = Array(repeating: initialValue, count: width*height)
        self.width = width
        self.height = height
    }

    private init(width: Int, height: Int, array: [A]) {
        self.width = width
        self.height = height
        self.array = array
    }

    subscript(column: Int, row: Int) -> A {
        get { array[row * width + column] }
        set { array[row * width + column] = newValue }
    }

    subscript(row row: Int) -> Array<A> {
        return Array(array[row * width..<(row+1)*width])
    }

    func map<B>(_ transform: (A) -> B) -> Matrix<B> {
        Matrix<B>(width: width, height: height, array: array.map(transform))
    }

    mutating func insert(row: Array<A>, at rowIdx: Int) {
        assert(row.count == width)
        assert(rowIdx <= height)
        array.insert(contentsOf: row, at: rowIdx * width)
        height += 1
    }

    func inserting(row: Array<A>, at rowIdx: Int) -> Matrix<A> {
        var copy = self
        copy.insert(row: row, at: rowIdx)
        return copy
    }
}

struct Score {
    private(set) var value: Int = 0

    private var log: [(Int, String)] = []

    var explanation: String {
        log.map { "\($0.0):\t\($0.1)"}.joined(separator: "\n")
    }

    mutating func add(_ amount: Int, reason: String) {
        value += amount
        log.append((amount, reason))
    }

    mutating func add(_ other: Score) {
        value += other.value
        log.append(contentsOf: other.log)
    }
}

extension Score: Comparable {
    static func < (lhs: Score, rhs: Score) -> Bool {
        return lhs.value < rhs.value
    }

    static func == (lhs: Score, rhs: Score) -> Bool {
        return lhs.value == rhs.value
    }
}

public let utf8Files = files.map { Array($0.utf8) }

extension Array where Element == [UInt8] {
    public func testFuzzyMatch(_ needle: String) -> [(string: [UInt8], score: Int)] {
        let n = Array<UInt8>(needle.utf8)
        var result: [([UInt8], Int)] = []
        result.reserveCapacity(self.count)
        let resultQueue = DispatchQueue(label: "result")
        let cores = ProcessInfo.processInfo.activeProcessorCount
        let chunkSize = count / cores

        DispatchQueue.concurrentPerform(iterations: cores) { idx in
            let start = idx * chunkSize
            let end = idx == cores - 1 ? endIndex : start + chunkSize
            let chunk: [([UInt8], Int)] = self[start..<end].compactMap {
                guard let match = $0.fuzzyMatch3(n) else { return nil }
                return ($0, match.score)
            }
            resultQueue.sync {
                result.append(contentsOf: chunk)
            }
        }
        return result
    }
}

extension Array where Element: Equatable {
    public func fuzzyMatch3(_ needle: [Element])
    -> (score: Int, matrix: Matrix<Int?>)? {
        var matrix = Matrix<Int?>(width: self.count, height: needle.count, initialValue: nil)
        if needle.isEmpty { return (score: 0, matrix: matrix) }
        guard needle.count <= count else { return nil }
        var prevMatchIdx: Int = -1
        for row in 0..<needle.count {
            let needleChar = needle[row]
            var firstMatchIdx: Int? = nil
            let remainderLength = needle.count - row - 1
            for column in (prevMatchIdx+1)..<(count-remainderLength) {
                let char = self[column]
                guard needleChar == char else {
                    continue
                }
                if firstMatchIdx == nil {
                    firstMatchIdx = column
                }
                var score = 1
                if row > 0 {
                    var maxPrevious = Int.min
                    for prevColumn in prevMatchIdx..<column {
                        guard let s = matrix[prevColumn, row - 1] else { continue }
                        let gapPenalty = (column - prevColumn) - 1
                        maxPrevious = Swift.max(maxPrevious, s - gapPenalty)
                    }
                    score += maxPrevious
                }
                matrix[column, row] = score
            }
            guard let firstIdx = firstMatchIdx else {
                return nil
            }
            prevMatchIdx = firstIdx
        }
        guard let score = matrix[row: needle.count-1].compactMap({ $0 }).max() else {
            return nil
        }
        return (score: score, matrix: matrix)
    }
}

extension Substring {
    func fuzzyMatch2(_ needle: Substring, gap: Int?) -> Score? {
        guard !needle.isEmpty else { return Score() }
        guard !isEmpty else { return nil }
        let skipScore = { dropFirst().fuzzyMatch2(needle, gap: gap.map { $0 + 1 }) }
        if first == needle.first {
            guard let s = dropFirst().fuzzyMatch2(needle.dropFirst(), gap: 0) else { return nil }
            var acceptScore = Score()
            if let g = gap, g > 0 {
                acceptScore.add(-g, reason: "Gap \(g)")
            }
            acceptScore.add(1, reason: "Match \(first!)")
            acceptScore.add(s)
            guard let skip = skipScore() else { return acceptScore }
            return Swift.max(skip, acceptScore)
        } else {
            return skipScore()
        }
    }
}

extension String {

    func fuzzyMatch(_ needle: String) -> (score: Score, indices: [String.Index])? {
        var ixs: [Index] = []
        var score = Score()
        if needle.isEmpty { return (score, []) }
        var remainder = needle[...].utf8
        var gap = 0
        for idx in utf8.indices {
            let char = utf8[idx]
            if char == remainder[remainder.startIndex] {
                if gap > 0, !ixs.isEmpty {
                    score.add(-gap, reason: "Gap \(gap)")
                }
                score.add(1, reason: "Match \(String(decoding: [char], as: UTF8.self))")
                gap = 0
                ixs.append(idx)
                remainder.removeFirst()
                if remainder.isEmpty { return (score, ixs) }
            } else {
                gap += 1
            }
        }
        return nil
    }
}

let demoFiles: [String] = [
    "module/string.swift",
    "str/testing.swift",
    "source/string.swift"
]

struct ContentView: View {
    @State var needle: String = ""
    
    var filtered: [(string: [UInt8], score: Int)] {
        os_signpost(.begin, log: log, name: "Search", "%@", needle)
        defer { os_signpost(.end, log: log, name: "Search", "%@", needle) }
        return utf8Files.testFuzzyMatch(needle).sorted { $0.score > $1.score }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(nsImage: search)
                    .padding(.leading, 10)
                TextField("", text: $needle).textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .font(.subheadline)
                Button(action: {
                    self.needle = ""
                }, label: {
                    Image(nsImage: close)
                        .padding()
                }).disabled(needle.isEmpty)
                .buttonStyle(BorderlessButtonStyle())
            }
            List(filtered.prefix(30), id: \.string) { result in
                HStack {
                    resultCell(result)
                }
            }
        }
    }

    func resultCell(_ result: (string: [UInt8], score: Int)) -> some View {
        return HStack {
            Text(String(result.score))
            Text(String(bytes: result.string, encoding: .utf8)!)
        }
    }
}

func highlight(string: String, indices: [String.Index]) -> Text {
    var result = Text("")
    for i in string.indices {
        let char = Text(String(string[i]))
        if indices.contains(i) {
            result = result + char.bold()
        } else {
            result = result + char.foregroundColor(.secondary)
        }
    }
    return result
}

struct MatrixView<A, V>: View where V: View {
    var matrix: Matrix<A>
    var cell: (A) -> V

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(0..<matrix.height), id: \.self) { row in
                HStack(alignment: .top) {
                    ForEach(Array(0..<self.matrix.width), id: \.self) { column in
                        self.cell(self.matrix[column, row])
                    }
                }
            }
        }
    }
}


// Hack to disable the focus ring
extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}

let close: NSImage = NSImage(named: "NSStopProgressFreestandingTemplate")!
let search: NSImage = NSImage(named: "NSTouchBarSearchTemplate")!
