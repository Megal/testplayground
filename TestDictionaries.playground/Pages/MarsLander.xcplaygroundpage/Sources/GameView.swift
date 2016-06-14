import Cocoa

public class GameViewController: NSViewController {
	public init()
	{
		let rect = NSRect(x: 0, y:0, width: 1050.0, height: 450.0)
		let myGameView = GameView(frame: rect)
		super.init(nibName: nil, bundle: nil)!
		view = myGameView
	}
	
	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

public extension GameViewController {

	public func setSurface(surface: [Int2d]) {
		(view as! GameView).setSurface(surface)
	}

	public func setSubOptimalPath(path: [(x: Double, y: Double)]) {
		(view as! GameView).setSubOptimalPath(path)
	}

	public func setLanderPath(path: [(x: Double, y: Double)]) {
		(view as! GameView).setLanderPath(path)
	}

	public var landerRotation: CGFloat {
		get {
			return (view as! GameView).landerRotation
		}
		set {
			(view as! GameView).landerRotation = newValue
		}
	}
}

class GameView: NSView {
	static let Width = 7000
	static let Height = 3000
	static let Scale = 0.15
	let scale = GameView.Scale
	let tailLength = 20

	let bgColor = NSColor.controlDarkShadowColor()
	let groundLineColor = NSColor.redColor()
	var groundPath = NSBezierPath()
	var landerPath: [NSBezierPath] = [NSBezierPath()]
	var suboptimalPath: [NSBezierPath] = [NSBezierPath()]
	var startLander = CGPointZero
	var endLander = CGPoint(x: Double(GameView.Width) * GameView.Scale, y: Double(GameView.Height) * GameView.Scale)
	let landerImage = NSImage(contentsOfURL: NSURL(string: "http://image005.flaticon.com/1/png/128/81/81889.png")!)!
	let landerVisibleSize = NSMakeSize(CGFloat(200.0*GameView.Scale), CGFloat(200.0*GameView.Scale))
	var landerRotation: CGFloat = 0

	func setSurface(surface: [Int2d]) {
		guard surface.count >= 2 else { groundPath = NSBezierPath(); return }

		let path = NSBezierPath()
		path.lineWidth = 2.0
		let (xi, yi) = surface[0]
		path.moveToPoint(NSPoint(x: Double(xi)*scale, y: Double(yi)*scale))

		for j in 1..<surface.count {
			let (xj, yj) = surface[j]
			path.lineToPoint(NSPoint(x: Double(xj)*scale, y: Double(yj)*scale))
		}

		groundPath = path
		setNeedsDisplayInRect(frame)
	}

	func setSubOptimalPath(path: [(x: Double, y: Double)]) {
		recyclePathBuffer( &suboptimalPath )
		addPath(path, to: &suboptimalPath)
	}

	func setLanderPath(lander: [(x: Double, y: Double)]) {
		recyclePathBuffer( &landerPath )
		addPath(lander, to: &landerPath)

		startLander = CGPoint(x: lander[0].x*scale, y: lander[0].y*scale)
		endLander = CGPoint(x: lander.last!.x*scale, y: lander.last!.y*scale)
		setNeedsDisplayInRect(frame)
	}

	func recyclePathBuffer(inout recyleable: [NSBezierPath]) {
		if recyleable.count > tailLength {
			recyleable = recyleable.dropLast(tailLength).flatMap{ $0 }
		}
	}

	func addPath(lander: [(x: Double, y: Double)], inout to output: [NSBezierPath] ) {
		guard lander.count >= 2 else { landerPath.append( NSBezierPath() ); return }

		let path = NSBezierPath()
		path.lineCapStyle = .SquareLineCapStyle
		path.lineJoinStyle = .RoundLineJoinStyle
		path.lineWidth = 1.5
		path.moveToPoint(NSPoint(x: lander[0].x*scale, y: lander[0].y*scale))
		for (_, next) in lander.enumerate().suffix(lander.count-1) {
			path.lineToPoint(NSPoint(x: next.x*scale, y: next.y*scale))
		}

		output.append(path)
	}

	override func drawRect(dirtyRect: NSRect) {
		bgColor.setFill()
		NSRectFill(dirtyRect)

		let context = NSGraphicsContext.currentContext()?.CGContext
		groundLineColor.setStroke()
		groundPath.stroke()

		let white = NSColor.whiteColor()
		let black = NSColor.blackColor()

		do { // draw lander
			CGContextSaveGState(context)
			defer { CGContextRestoreGState(context) }

			let transform = NSAffineTransform()
			transform.translateXBy(startLander.x, yBy: startLander.y)
			transform.rotateByDegrees(landerRotation)
			transform.set()

			let targetRect = NSMakeRect(0, 0, landerVisibleSize.width, landerVisibleSize.height)
			let centered = NSOffsetRect(targetRect, -0.5*landerVisibleSize.width, -0.5*landerVisibleSize.height)
			landerImage.drawInRect(centered, fromRect: NSZeroRect, operation: .CompositeXOR, fraction: 1.0)
		}

		if suboptimalPath.count > 1 {
			var drawn = 0
			for (_, path) in suboptimalPath.reverse().enumerate().dropFirst() {
				guard drawn < tailLength else { break }

				let color = NSColor.yellowColor().blendedColorWithFraction(CGFloat(drawn) / CGFloat(tailLength), ofColor: NSColor.redColor())!
				color.colorWithAlphaComponent(0.5).setStroke()

				path.lineWidth = 0.5
				path.setLineDash([5.0, 5.0], count: 2, phase: 0.0)
				path.stroke()

				drawn += 1
			}
		}

		if landerPath.count > 1 {
			var drawn = 0
			for (_, path) in landerPath.reverse().enumerate().dropFirst() {
				guard drawn < tailLength else { break }

				let color = white.blendedColorWithFraction(CGFloat(drawn+tailLength) / CGFloat(2*tailLength), ofColor: black)!
				color.setStroke()

				path.lineWidth *= 0.8
				path.stroke()

				drawn += 1
			}
		}

		do { // draw path
			black.setStroke()
			let path = landerPath.last!
			path.lineWidth += 2.0
			path.stroke()
			path.lineWidth -= 2.0

			CGContextBeginTransparencyLayer(context, nil)
			defer {
				CGContextEndTransparencyLayer(context)
			}

			white.setStroke()
			path.stroke()
			CGContextSetBlendMode(context, .SourceIn)

			let colors          = [NSColor.greenColor().CGColor, NSColor.yellowColor().CGColor, NSColor.redColor().CGColor]
			let colorSpace      = CGColorSpaceCreateDeviceRGB()
			let colorLocations  :[CGFloat] = [0.0, 0.5, 1.0]
			let gradient        = CGGradientCreateWithColors(colorSpace, colors, colorLocations)
			let startPoint      = startLander
			let endPoint        = endLander

			CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions.DrawsAfterEndLocation.union(CGGradientDrawingOptions.DrawsBeforeStartLocation))
		}

	}
}