import Darwin.C
import XCPlayground

extension Dictionary {

	init(_ pairs: [Element]) {
		self.init()
		for (k, v) in pairs {
			self[k] = v
		}
	}
}

let randgen = RandomDoubleGenerator.singleton
//let a = 4 / 3.0
var stat: [Double] = []
var testA = (0.005).stride(through: 1, by: 0.005).map{ Double($0) }
//let testB = (10.0).stride(through: 100.0, by: 10).map{ Double($0) }
//testA += testB
let page = XCPlaygroundPage.currentPage
page.needsIndefiniteExecution = true

let F1 = { (k: Double) in
	(k <= 1)
		? ( (2*k) / (k+1) )
		: ( (k+1) / 2.0 )
}

//for a in testA {
//	var wins = 0
//	let N = 2000
//	let k = F1(a)
//	for _ in 0..<N {
//		let randomA = randgen[0..<k]
//		let random1 = randgen[0..<1]
//		if randomA > random1 { wins += 1 }
//	}
//	let statA = Double( Double(wins) / Double(N-wins) )
//	let expectFlat = statA / a
//	XCPlaygroundPage.currentPage.captureValue( statA, withIdentifier: "testA")
//	XCPlaygroundPage.currentPage.captureValue( expectFlat, withIdentifier: "expectFlat")
//
//	stat.append(statA)
//}
//stat
//abort()

infix operator .--> {
associativity left
precedence 152
}
//! Apply operation using dot syntax
public func .--> <U, V>(arg: U, transform: (U) -> V ) -> V {
	return transform(arg)
}

let val = [
	"A": 10,
	"B": 30,
	"C": 22,
	"D": 15,
	"E": 19,
	"F": 11,
	"H": 3,
	"I": 5,
	"J": 9,
]
let chances = val.map { $0.1 }
let sum = chances.reduce(0) { (sum, item) in sum + item }.-->Double.init
let avg = sum / Double(chances.count)

let norm = val.map { (k, v) in
	(key: k, value: Double(v) / sum)
}
.sort { $0.value > $1.value }

let playball = norm.map { (key, value) in (key, F1(value)) }
playball

let H1 = 1
let N = 5000
func dictionaryWithArrayOfPairs<K, V> (array: Array<(K, V)>) -> [K:V] {
	var newDict: [K:V] = [:]
	for (key, value) in array {
		newDict[key] = value
	}

	return newDict
}

var survivals = val.map { (key, _) in
	(key: key, value: 0)
}
.--> dictionaryWithArrayOfPairs


for _ in 0..<N {
	playball.map { (key, value) in
		(key, randgen[0..<value])
	}
	.sort { (left, right) in
		left.1 > right.1
	}
	.prefix( H1 )
	.forEach { (key, _) in
		survivals[key]! += 1
	}
}

survivals
let survivedPercentage = survivals.map { (key, value) in
	(key: key, value: Double(value)/Double(N))
}
.sort { $0.value > $1.value }
survivedPercentage
norm

let sortedSurvivedKeys = survivedPercentage.map { $0.key }
let sortedNormKeys = norm.map { $0.0 }
sortedSurvivedKeys
sortedNormKeys
