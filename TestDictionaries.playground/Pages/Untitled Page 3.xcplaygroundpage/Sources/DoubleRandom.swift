import Darwin.C

public struct RandomDoubleGenerator {
	private init() { srand48(Int(arc4random())) }
	public static let singleton = RandomDoubleGenerator()
}

//! Get double in desired interval
public extension RandomDoubleGenerator {

	struct Arc4Ranges {
		static let СlosedDenominator: Double = Double(UInt32.max)
		static let HalfOpenDenominator: Double = Double(Int64(UInt32.max) + 1)
	}

	subscript(interval: ClosedInterval<Double>) -> Double {
		let normalized = Double(arc4random()) / RandomDoubleGenerator.Arc4Ranges.СlosedDenominator
		let width = interval.end - interval.start
		let scaled = normalized * width

		return interval.start + scaled
	}

	subscript(interval: HalfOpenInterval<Double>) -> Double {
		let normalized = Double(arc4random()) / RandomDoubleGenerator.Arc4Ranges.HalfOpenDenominator
		let width = interval.end - interval.start
		let scaled = normalized * width

		return interval.start + scaled
	}
}

public struct WeightedRandom<T> {
	typealias IntervalToValue = (interval: HalfOpenInterval<Double>, value: T)
	private var probabilityMap: [IntervalToValue] = []
	private var weightSum = 0.0
}

enum WeightedRandomError : ErrorType {
	case InvalidArgument
}

public extension WeightedRandom {

	mutating func add(value: T, weight: Double) throws {
		guard weight.isNormal && weight > 0 else { throw WeightedRandomError.InvalidArgument }

		let newWeightSum = weightSum + weight
		probabilityMap.append((weightSum..<newWeightSum, value))
		weightSum = newWeightSum
	}

	func getRandomObject() -> T? {
		guard !probabilityMap.isEmpty else { return nil }

		let randomizer = RandomDoubleGenerator.singleton
		let number = randomizer[0 ..< weightSum]
		let v = probabilityMap.filter { (interval, value) in interval ~= number }.first?.value

		return v
	}
}