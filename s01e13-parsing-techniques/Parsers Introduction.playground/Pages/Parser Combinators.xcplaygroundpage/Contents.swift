import Foundation


let digit = character(condition: { $0.isNumber })

let int = digit.many.map { characters in Int(String(characters))! }

let multiplication = curry({ x, y in x * (y ?? 1) }) <^> int <*> (string("*") *> int).optional

let addition = curry({ x, y in x + (y ?? 0) }) <^> multiplication <*> (string("+") *> multiplication).optional

multiplication.run("2+5*3")
