import Foundation

final class Parser {
    let scanner: Scanner
    
    init (_ string: String) {
        scanner = Scanner(string: string)
    }
    
    func int() -> Int? {
        var result: Int = 0
        guard scanner.scanInt(&result) else { return nil }
        return result
    }
    
    func multiplication() -> Int? {
        let oldIndex = scanner.currentIndex
        guard let lhs = int()  else { return nil }
        guard scanner.scanString("*") != nil else { return lhs }
        guard let rhs = int() else {
            scanner.currentIndex = oldIndex
            return nil
        }
        return lhs * rhs
    }
    
    func addition() -> Int? {
        let oldIndex = scanner.currentIndex
        guard let lhs = multiplication()  else { return nil }
        guard scanner.scanString("+") != nil else { return lhs }
        guard let rhs = multiplication() else {
            scanner.currentIndex = oldIndex
            return nil
        }
        return lhs + rhs
    }
}

let parser = Parser("23")
parser.int()

let parser2 = Parser("23*2")
parser2.multiplication()


let parser3 = Parser("23+2*3")
parser3.addition()

let parser4 = Parser("2+3")
parser4.addition()



