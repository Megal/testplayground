import Darwin.C

public struct Generation {
	public var current: [Chromosome] = []
	public let populationLimit = 20
	public let crossingoverRate = 2
	public let mutationRate = 3
	public let world: World
	public var lander: MarsLander
	public var ordered = false

	public var lastEvaluatedPath: [Double2d] = []
	public typealias Comparation = (left: MarsLander, right: MarsLander) -> Bool
	public var fitnessFunc: [(fn: Comparation, weight: Double)] = []

	public init(world: World, lander: MarsLander) {
		self.world = world
		self.lander = lander
		current.append(Chromosome(genes: [Chromosome.neutralGene], ttl: -1, blackBox: nil))
	}
}

public extension Generation {

	mutating func evalTTL() {
		guard ordered == false else { return }

		for (currentIndex, sample) in current.enumerate() {
			guard sample.ttl < 0 else { continue }

			evalTTL(&current[currentIndex])
		}

		current.sortInPlace{ (a, b) in a.ttl > b.ttl }
		ordered = true
	}

	mutating func sort() {
		guard !ordered else { return }

		// TODO Implement sorting using additional fitess functions
//		for (fn, weight) in fitnessFunc {
//			let indexes = (0..<current.count).map { Int($0) }
//			indexes.sortInPlace {
//				let left = current[$0]
//				let right = current[$1]
//				return left >
//			}
//		}

		current.sortInPlace{ (a, b) in a.ttl > b.ttl }
		ordered = true
	}

	mutating func evalBest() {
		evalTTL()
		evalTTL(&current[0])
	}

	mutating func evalSuboptimal(place n: Int ) {
		evalTTL()
		evalTTL(&current[n])
	}

	private mutating func evalTTL(inout chromosome: Chromosome) {
		let oldTTL = chromosome.ttl
		defer {
			if chromosome.ttl != oldTTL || oldTTL < 0 {
				ordered = false
			}
		}

		lastEvaluatedPath.removeAll()
		var evolvingLander = lander; lastEvaluatedPath.append((x: evolvingLander.X, y: evolvingLander.Y))
		var ttl = 0
		for (geneIndex, (action: action, duration: duration)) in chromosome.genes.enumerate() {
			for turnSameAction in 0..<duration {
				ttl += 1
				let nextLander = world.simulate(marsLander: evolvingLander, action: action)
				defer {
					lastEvaluatedPath.append((x: evolvingLander.X, y: evolvingLander.Y))
					evolvingLander = nextLander
				}

				if world.testSafeZone(marsLander: nextLander) { continue }

				let isLanded = world.testLanded(marsLander: nextLander)
				if isLanded {
					chromosome.ttl = Chromosome.maxTTL + nextLander.fuel
					chromosome.blackBox = nextLander
					return
				} else {
					let alternativeLander = world.simulate(marsLander: evolvingLander, action: Chromosome.neutralGene.action)
					if world.testLanded(marsLander: alternativeLander) {
						let prefixChromosome = chromosome.prefix(ttl-1)
						chromosome = prefixChromosome
						chromosome.ttl = Chromosome.maxTTL + alternativeLander.fuel
						chromosome.blackBox = alternativeLander
					} else {
						chromosome.ttl = ttl
						chromosome.blackBox = nextLander
						return
					}
				}
			}
		}
		assert(false)
	}
}

public extension Generation {

	func generateRandomAction() -> Chromosome.Action {
		return Chromosome.Action(rotate: random() % 181 - 90, power: random() % 5)
	}

	func generateMonoChromosome(action: Chromosome.Action) -> Chromosome {
		return Chromosome(genes: [(action: action, duration: Chromosome.maxTTL)], ttl: -1, blackBox: nil)
	}

	mutating func populateToLimitWithRandom() {
		current.reserveCapacity(populationLimit * 2)
		for _ in current.count..<populationLimit {
			let newChromosome = Chromosome(
				genes: [(action: generateRandomAction(), duration: Chromosome.maxTTL)],
				ttl: -1,
				blackBox: nil)
			current.append(newChromosome)
		}

		ordered = false
	}

	mutating func addMutantsWithRandomTailOrHead() {
		let countBeforeMutation = current.count
		for i in 0..<countBeforeMutation {
			let sample = current[i]
			current.append(makeMutant(sample, species: .HeadMutant))
			current.append(makeMutant(sample, species: .TailMutant))
			current.append(makeMutant(sample, species: .BodyMutant))
		}

		ordered = false
	}

	enum MutantSpecies {
		case TailMutant
		case HeadMutant
		case BodyMutant
	}

	func makeMutant(sample: Chromosome, species: MutantSpecies) -> Chromosome {
		let mono = generateMonoChromosome(generateRandomAction())

		guard case let ttl = UInt32(sample.ttl) where sample.ttl > 2 else { return mono }
		let cut1 = Int(1 + arc4random_uniform(ttl / 2))
		let cut2 = Int(1 + (ttl + 1) / 2 + arc4random_uniform((ttl - 2) / 2))

		switch( species ) {
		case .HeadMutant: return Chromosome.combine(head: mono, tail: sample, at: cut1)
		case .TailMutant: return Chromosome.combine(head: sample, tail: mono, at: cut2)
		case .BodyMutant: do {
				let withHead = Chromosome.combine(head: sample, tail: mono, at: cut1)
				let withHeadAndTail = Chromosome.combine(head: withHead, tail: sample, at: cut2)
				return withHeadAndTail
			}
		}
	}


	mutating func reducePopulation() {
		reducePopulation(populationLimit)
	}

	mutating func reducePopulation(limit: Int) {
		guard current.count > limit else { return }

		evalTTL()
		current.removeRange(limit..<current.count)
	}

	mutating func bestChomosome() -> Chromosome {
		evalTTL()
		return current.first!
	}

	mutating func incrementAge(marsLander next: MarsLander) {
		lander = next
		for i in 0..<current.count {
			current[i].incrementAge()
		}

		ordered = false
	}
}

public extension Generation {

	mutating func evolution(cycles n: Int) {
		for _ in 0..<n {
			reducePopulation(populationLimit/5)
			addMutantsWithRandomTailOrHead()
			populateToLimitWithRandom()
		}
	}
}