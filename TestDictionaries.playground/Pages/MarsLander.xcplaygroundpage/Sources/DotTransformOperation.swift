//  Created by Svyatoshenko "Megal" Misha on 2016-06-10

infix operator .--> {
	associativity left
	precedence 152
}
//! Apply operation using dot syntax
public func .--> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}