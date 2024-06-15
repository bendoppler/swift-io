import XCTest

extension CountableClosedRange {
    func merge(_ other: CountableClosedRange) -> CountableClosedRange {
        return Swift.min(lowerBound, other.lowerBound)...Swift.max(upperBound, other.upperBound)
    }
    
    func overlapsOrAdjacent(_ other: CountableClosedRange) -> Bool {
        return ((lowerBound.advanced(by: -1))...(upperBound.advanced(by: 1))).overlaps(other)
    }
}

extension Sequence {
    func reduce<A>(initial: A, combine: (inout A, Iterator.Element) -> ()) -> A {
        var result = initial
        for element in self {
            combine(&result, element)
        }
        return result
    }
}

struct IndexSet {
    typealias RangeType = CountableClosedRange<Int>
    
    // Invariant: sorted by lower bound
    var sortedRanges: [RangeType] = []
    
    mutating func insert(_ element: RangeType) {
        sortedRanges.append(element)
        sortedRanges.sort { $0.lowerBound < $1.lowerBound }
        merge()
    }
    
    private mutating func merge() {
        sortedRanges = sortedRanges.reduce(initial: [], combine: { newRanges, range in
            if let last = newRanges.last, last.overlapsOrAdjacent(range) {
                newRanges[newRanges.endIndex - 1] = last.merge(range)
            } else {
                newRanges.append(range)
            }
        })
    }
}

extension IndexSet {
    struct RangeView: Sequence {
        let base: IndexSet
        
        func makeIterator() -> AnyIterator<RangeType> {
            return AnyIterator(base.sortedRanges.makeIterator())
        }
    }
    
    var rangeView: RangeView {
        return RangeView(base: self)
    }
}

extension IndexSet: Sequence {
    func makeIterator() -> AnyIterator<Int> {
        return AnyIterator(rangeView.joined().makeIterator())
//        return Iterator(rangeIterator: rangeView.makeIterator(), elementsIterator: nil)
    }
}

struct JoinedIterator<S: Sequence>: IteratorProtocol where S.Iterator.Element: Sequence {
    var rangeIterator: S.Iterator
    var elementsIterator: S.Iterator.Element.Iterator?
    
    mutating func next() -> S.Iterator.Element.Iterator.Element? {
        if let element = elementsIterator?.next() {
            return element
        } else {
            if let range = rangeIterator.next() {
                elementsIterator = range.makeIterator()
                return elementsIterator?.next()
            } else {
                return nil
            }
        }
    }
}

class IndexSetWithTestsTests: XCTestCase {
    func testInsertion() {
        XCTContext.runActivity(named: "Test insert element into index set") { _ in
            var set = IndexSet()
            set.insert(5...6)
            set.insert(1...2)
            for range in set.rangeView {
                print(range)
            }
            
            for idx in set {
                print(idx)
            }
            XCTAssert(set.sortedRanges == [1...2, 5...6])
        }
    }
    
    func testMerging() {
        XCTContext.runActivity(named: "Test merging element index set") { _ in
            var set = IndexSet()
            set.insert(5...6)
            set.insert(3...6)
            for range in set.rangeView {
                print(range)
            }
            for idx in set {
                print(idx)
            }
            XCTAssert(set.sortedRanges == [3...6])
        }
    }
    
    func testMergingAdjacent() {
        XCTContext.runActivity(named: "Test merging adjacent element index set") { _ in
            var set = IndexSet()
            set.insert(5...6)
            set.insert(3...4)
            for range in set.rangeView {
                print(range)
            }
            for idx in set {
                print(idx)
            }
            XCTAssert(set.sortedRanges == [3...6])
        }
    }
}
