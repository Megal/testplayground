//  Created by Svyatoshenko "Megal" Misha on 2016-06-09

let a = Double(5)

infix operator .--> {
	associativity left
	precedence 152
}
//! Apply operation using dot syntax
public func .--> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}

public func aaa(arg: Int, transform: (Int) -> Double ) -> Double {
	return transform(arg)
}
let b = aaa(5) { Double($0) }

let c = 5.-->{ Double($0) }

let makeDouble = { (arg: Int) in Double(arg) }
let d = 5.-->makeDouble

let e = 5 .--> Double.init

let f = 5
	.--> Double.init

let g = 3 * 5.-->Double.init + 10

infix operator .~=> {
associativity left
precedence 152
}
//! Apply operation using dot syntax
public func .~=> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}

let h = 3 * 5.~=>Double.init + 10

