import Foundation

let a = (159, 48, 181)
let s = String.init(format:"%ld", 159)

let hex = String(159, radix: 15) + String(48, radix: 15) + String(181, radix: 15)
hex
