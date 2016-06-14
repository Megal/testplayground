import Foundation

public typealias Int2d = (x: Int, y: Int)
public typealias Double2d = (x: Double, y: Double)
public func +(a: Int2d, b: Int2d) -> Int2d { return (a.x+b.x, a.y+b.y) }
public func -(a: Int2d, b: Int2d) -> Int2d { return (a.x-b.x, a.y-b.y) }

public func dist<T where T:Comparable, T:Strideable>(a: T, _ b: T) -> T.Stride {
	if a < b {
		return b - a
	}
	else {
		return a - b
	}
}

public func sign<T where T:IntegerLiteralConvertible, T:Comparable>(number: T) -> T {
	if number >= 0 {
		return 1
	} else {
		return -1
	}
}

public func clamp(number: Int, range: Range<Int>) -> Int? {
	guard let min = range.minElement(), max = range.maxElement() else {
		return nil
	}
	if number < min {
		return min
	} else if number >= max {
		return max
	} else {
		return number
	}
}

public func makeClosedIntervalWithEpsilonMargin(from a: Double, to b: Double, epsilon: Double = 1e-9) -> ClosedInterval<Double>?
{
	if a < b {
		return (a-epsilon ... b+epsilon)
	} else if b < a {
		return (b-epsilon ... a+epsilon)
	} else {
		return nil
	}
}


