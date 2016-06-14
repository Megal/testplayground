import Foundation

public struct MarsLander {
	public var X: Double
	public var Y: Double
	public var hSpeed: Double
	public var vSpeed: Double
	public var fuel: Int
	public var rotate: Int
	public var power: Int
}

public extension MarsLander {

	init?(parseFromInput input: String) {
		let input = input.componentsSeparatedByString(" ").flatMap { Int($0) }
		guard input.count == 7 else {
			return nil
		}

		self.init(
			X: Double(input[0]),
			Y: Double(input[1]),
			hSpeed: Double(input[2]),
			vSpeed: Double(input[3]),
			fuel: input[4],
			rotate: input[5],
			power: input[6]
		)
	}
}

public extension MarsLander {

	public struct Action {
		public let rotate, power: Int
		public init(rotate: Int, power: Int) { self.rotate = rotate; self.power = power }
	}

	public func clampedAction(action: Action) -> Action {
		let powerClamp = Range(interval: (0 ... fuel as ClosedInterval).clamp(0...4 as ClosedInterval).clamp(power-1 ... power+1))
		let rotateClamp = Range(interval: (-90...90 as ClosedInterval).clamp(rotate-15 ... rotate+15))

		let clamped = Action(
			rotate: clamp(action.rotate, range: rotateClamp)!,
			power: clamp(action.power, range: powerClamp)!
		)
		return clamped
	}
}

extension MarsLander: CustomStringConvertible {

	static let OneDigitAfterDecimalPoint: (Double) -> String = {
		let formatter = NSNumberFormatter()
		formatter.minimumFractionDigits = 1
		formatter.maximumFractionDigits = 1

		return { (number: Double) -> String in formatter.stringFromNumber(NSNumber(double: number))! }
	}()

	public var description: String {
		let d1 = MarsLander.OneDigitAfterDecimalPoint
		return "at:(\(d1(X)), \(d1(Y))) v:(\(d1(hSpeed)), \(d1(vSpeed))) rot:\(rotate) pow:\(power) fuel:\(fuel)"
	}
}

infix operator ~== { associativity left precedence 130 }
//! Equals in acceptable precision
public func ~==(left: MarsLander, right: MarsLander) -> Bool {
	guard left.fuel == right.fuel && left.rotate == right.rotate && left.power == right.power else {
		return false
	}

	let epsilon = 1.0 + 1e-9
	guard fabs(left.X - right.X) < epsilon else {
		return false
	}
	guard fabs(left.Y - right.Y) < epsilon else {
		return false
	}
	guard fabs(left.vSpeed - right.vSpeed) < epsilon else {
		return false
	}
	guard fabs(left.hSpeed - right.hSpeed) < epsilon else {
		return false
	}

	return true
}

