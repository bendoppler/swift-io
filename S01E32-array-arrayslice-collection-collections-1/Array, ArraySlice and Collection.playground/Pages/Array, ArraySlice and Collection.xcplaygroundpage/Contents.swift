import Foundation

//extension Array {
//    func split(batchSize: Int) -> [[Element]] {
//        return self[startIndex..<endIndex].split(batchSize: batchSize)
//    }
//}
//
//extension ArraySlice {
//    func split(batchSize: Int) -> [[Element]] {
//        var result: [[Element]] = []
//        for idx in stride(from: startIndex, to: endIndex, by: batchSize) {
//            let end = Swift.min(idx+batchSize, endIndex)
//            result.append(Array(self[idx..<end]))
//        }
//        return result
//    }
//}

extension Collection {
    func split(batchSize: IndexDistance) -> [SubSequence] {
        var result: [SubSequence] = []
        var currentIndex = startIndex
        while currentIndex < endIndex {
            let end = self.index(currentIndex, offsetBy: batchSize, limitedBy: endIndex) ?? endIndex
            result.append(self[currentIndex..<end])
            currentIndex = end
        }
        return result
    }
}

extension Sequence {
    func split(batchSize: Int) -> AnySequence<[Iterator.Element]> {
        return AnySequence { () -> AnyIterator<[Iterator.Element]> in
            var iterator = self.makeIterator()
            return AnyIterator {
                var batch: [Iterator.Element] = []
                while batch.count < batchSize, let ele = iterator.next() {
                    batch.append(ele)
                }
                return batch.isEmpty ? nil : batch
            }
        }
    }
}

let array: [Int] = [1, 2, 3, 4]
let slice = array.suffix(from: 1)


array.split(batchSize: 3)
slice.split(batchSize: 2)

dump("hello world".split(batchSize: 2).map { String($0) })

final class ReadRandom: IteratorProtocol {
    let handle = FileHandle(forReadingAtPath: "/dev/urandom")!
    deinit {
        handle.closeFile()
    }
    
    func next() -> UInt8? {
        let data = handle.readData(ofLength: 1)
        return data[0]
    }
}

let randomSource = ReadRandom()
randomSource.next()
let randomSequence = AnySequence { ReadRandom() }

//for element in randomSequence {
//    print(element)
//}

//Array(randomSequence.split(batchSize: 3).prefix(5))

randomSequence.split(batchSize: 3).lazy.map { "\($0)" }

