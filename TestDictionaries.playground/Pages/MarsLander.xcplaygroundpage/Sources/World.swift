import Foundation

public struct World {
	public var surface: [Int2d]
	public var maxY: Int = 0
	public var target: Double2d = (0, 0)
	public let gravity = 3.711
	public let a_land = 4.0 - 3.711
	public let a_8 = 0.55669240384026

	public static func parseFromInput() -> World {
		let surfaceN = Int(readLine()!)! // the number of points used to draw the surface of Mars.
		var surface = [Int2d]()
		for _ in 0..<surfaceN {
			let inputs = (readLine()!).componentsSeparatedByString(" ")
			let landX = Int(inputs[0])! // X coordinate of a surface point. (0 to 6999)
			let landY = Int(inputs[1])! // Y coordinate of a surface point. By linking all the points together in a sequential fashion, you form the surface of Mars.
			surface.append((x: landX, y:landY))
		}

		return World(surface: surface)
	}

	public init(surface initSurface: [Int2d]) {
		surface = initSurface

		for point in surface {
			maxY = [maxY, point.y].sort(>)[0]
		}

		for (i, point1) in surface.enumerate() where i<surface.count-1 {
			let point2 = surface[i+1]
			if point1.y == point2.y {
				target = (x: Double(point1.x + point2.x)/2, y: Double(point1.y))
				break
			}
		}
	}
}

public extension World {

	func freefallTime(vSpeed v1: Double, altitude h: Double) -> Double {
		let v2 = sqrt( v1*v1 + 2*gravity*h )
		let t = (v2 - v1) / gravity

		return t
	}

	func simulate(marsLander lander: MarsLander, action actionBeforeClamp: MarsLander.Action) -> MarsLander {
		let action = lander.clampedAction(actionBeforeClamp)

		let trueAngle = Double(90+action.rotate) * M_PI/180.0
		let (dvx, dvy) = (
			Double(action.power) * cos(trueAngle),
			Double(action.power) * sin(trueAngle) - gravity
		)

		var next = lander
		next.fuel -= action.power
		next.hSpeed += dvx
		next.vSpeed += dvy
		next.X += (lander.hSpeed + next.hSpeed) / 2
		next.Y += (lander.vSpeed + next.vSpeed) / 2
		next.power = action.power
		next.rotate = action.rotate

		return next
	}

	func testSafeZone(marsLander lander: MarsLander) -> Bool {
		guard (0.0..<7000.0) ~= lander.X else {
			return false
		}
		guard (0.0..<3000.0) ~= lander.Y else {
			return false
		}

		for i in 0..<surface.count-1 {
			let (x1, x2) = (Double(surface[i].x), Double(surface[i+1].x))
			let (y1, y2) = (Double(surface[i].y), Double(surface[i+1].y))
			if let x12 = makeClosedIntervalWithEpsilonMargin(from: x1, to: x2) where x12.contains(lander.X) {
				let t = (lander.X - x1) / (x2 - x1)
				let yt = y1 + t*(y2 - y1)

				return lander.Y > yt
			}
		}

		return true
	}

	func testLanded(marsLander lander: MarsLander) -> Bool {
		let x12 = makeClosedIntervalWithEpsilonMargin(from: target.x-500, to: target.x+500)!
		let y12 = makeClosedIntervalWithEpsilonMargin(from: target.y-40, to: target.y)!
		guard x12 ~= lander.X && y12 ~= lander.Y else {
			return false
		}
		guard lander.vSpeed > -40 else {
			return false
		}
		guard fabs(lander.hSpeed) < 20 else {
			return false
		}
		guard lander.rotate == 0 else {
			return false
		}
		
		return true
	}
}

