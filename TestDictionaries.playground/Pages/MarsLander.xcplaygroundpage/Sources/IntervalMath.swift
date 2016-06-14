import Foundation

public extension Range where Element : Comparable {

	init(interval: ClosedInterval<Element>) {
		startIndex = interval.start
		endIndex = interval.end.successor()
	}

	init(interval: HalfOpenInterval<Element>) {
		startIndex = interval.start
		endIndex = interval.end
	}
}

public extension IntervalType {

	public var hashValue: Int {
		return "\(self)".hashValue
	}
}
extension HalfOpenInterval: Hashable {}
extension ClosedInterval: Hashable {}

extension Range: Hashable {

	public var hashValue: Int {
		return "\(self)".hashValue
	}
}