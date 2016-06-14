//  Created by Svyatoshenko "Megal" Misha on 2016-04-28

import Foundation

getpid()
//system("lsof -p \(getpid()) >&2")
//system("cat \"\(__FILE__)\" >&2")
// system("lsof -w -p \(getpid()) >&2")
// system("find /opt/ -lname swift >&2")
system("/opt/coderunner/swift/usr/bin/swiftc -version >&2")

import XCPlayground
let myGameVC = GameViewController()
XCPlaygroundPage.currentPage.liveView = myGameVC.view

if let inputFile = NSBundle.mainBundle().pathForResource("input", ofType: "txt") {
	freopen(inputFile, "r", stdin)
}

let world = World.parseFromInput()
myGameVC.setSurface(world.surface)


var action: MarsLander.Action!
var landerExpected: MarsLander!
var generation: Generation!
var missionCompleted = false
for turn in 0..<3000 {
	if missionCompleted { break }

	defer {
		print("\(action.rotate) \(action.power)")
		log("Expect Mars Lander: \(landerExpected)")
	}

	var lander: MarsLander
	if feof(stdin) != 0 {
		lander = landerExpected
	} else {
		let line = readLine()!
		lander = MarsLander(parseFromInput: line)!
		log("Read   Mars Lander: \(lander)")
		if let landerExpected = landerExpected {
			if lander ~== landerExpected {
				lander = landerExpected
			} else {
				log("Not close to expected, using data from input")
			}
		}
	}

	if world.testLanded(marsLander: lander) {
		log("Congratulations! successfully landed")
		missionCompleted = true
	} else if !world.testSafeZone(marsLander: lander) {
		log("Mission failed!")
		missionCompleted = true
	}
	myGameVC.landerRotation = CGFloat(lander.rotate)

	let testAngle = { (angle: Int) in dist( lander.rotate, angle ) < 90 ? true : false }

	if turn == 0 {
		log("Calculating traectory \((lander.X, lander.Y)) -> \(world.target): ...")
		generation = Generation(world: world, lander: lander)
		generation.populateToLimitWithRandom()
		generation.evolution(cycles: 10)
	} else {
		generation.incrementAge(marsLander: lander)
		generation.evalTTL()
		generation.evolution(cycles: 3)
	}

	action = generation.bestChomosome().genes[0].action
	for place in (1..<10).reverse() {
		generation.populationLimit * (1 + (place) / (10))
		generation.evalSuboptimal(place: place)
		myGameVC.setSubOptimalPath(generation.lastEvaluatedPath)
	}
	generation.evalBest()
	myGameVC.setLanderPath(generation.lastEvaluatedPath)
	XCPlaygroundPage.currentPage.liveView

	landerExpected = world.simulate(marsLander: lander, action: action)
}