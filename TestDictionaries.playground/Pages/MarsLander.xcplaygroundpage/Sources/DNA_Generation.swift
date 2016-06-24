import Darwin.C

public struct Generation {
	public var current: [Chromosome] = []
	public var fitnessScore: [Double] = []

	public let populationLimit = 20
	public let crossingoverRate = 2
	public let mutationRate = 3
	public let world: World
	public var lander: MarsLander
	public var fitnessScored = false {
		didSet { sorted = false	}
	}
	public var sortedIndexes: [Int] = []
	public var sorted = false

	public var lastEvaluatedPath: [Double2d] = []
	//! 0 is acceptable, >0 and more is worse
	public typealias ErrorFn = (MarsLander) -> Double
	public var fitnessFunc: [(fn: ErrorFn, weight: Double)] = []

	public init(world: World, lander: MarsLander) {
		self.world = world
		self.lander = lander
		current.append(Chromosome(genes: [Chromosome.neutralGene], ttl: -1, blackBox: nil))
	}
}

public extension Generation {

	mutating func evalTTL() {
		guard fitnessScored == false else { return }

		for (currentIndex, sample) in current.enumerate() {
			guard sample.ttl < 0 else { continue }

			evalTTL(&current[currentIndex])
		}

		evalFitness()
	}

	mutating func evalFitness() {
		guard !fitnessScored else { return }
		defer {
			fitnessScored = true
		}

		guard case let N = current.count where N > 0 else { return }
		fitnessScore = [Double](count: N, repeatedValue: 1.0)

		for (fn, denormWeight) in fitnessFunc {
			let weight = denormWeight / Double(N)
			let errors = current.map { $0.blackBox!.-->fn }
			let indexes = (0..<N).map { (i: Int($0), e: errors[$0]) }
			let worstFirst = indexes.sort { $0.e > $1.e }

			var worse = 0
			for i in 1..<N {
				let prev = worstFirst[i-1]
				let cur = worstFirst[i]

				if prev.e > 1e-9 + cur.e {
					worse = i
				}

				fitnessScore[cur.i] += weight * Double(worse)
			}
		}
	}

	mutating func sort() {
		guard fitnessScored else { assert(false, "you should call evalFitness() before this method"); return }
		guard !sorted else { return }
		defer {
			sorted = true
		}

		guard case let N = current.count where N > 0 else { return }
		sortedIndexes = (0..<N).map { Int($0) }
		.sort { (i, j) in
			if fitnessScore[i] == fitnessScore[j] {
				return current[i].ttl > current[j].ttl
			} else {
				return fitnessScore[i] > fitnessScore[j]
			}
		}
	}

	mutating func evalBest() {
		evalTTL()
		sort()
		evalTTL(&current[sortedIndexes[0]])
	}

	mutating func evalSuboptimal(place n: Int ) {
		evalTTL()
		sort()
		evalTTL(&current[sortedIndexes[n]])
	}

	private mutating func evalTTL(inout chromosome: Chromosome) {
		let oldTTL = chromosome.ttl
		defer {
			assert(chromosome.blackBox != nil, "blackbox is necessary")
			if chromosome.blackBox == nil {fatal("assert not working")}
			if chromosome.ttl != oldTTL || oldTTL < 0 {
				fitnessScored = false
			}
		}

		lastEvaluatedPath.removeAll()
		var evolvingLander = lander; lastEvaluatedPath.append((x: evolvingLander.X, y: evolvingLander.Y))
		var ttl = 0
		chromosome.genes.append(Chromosome.neutralGene)
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
					let prefixChromosome = chromosome.prefix(ttl)
					chromosome = prefixChromosome
					chromosome.ttl = Chromosome.maxTTL + nextLander.fuel
					chromosome.blackBox = nextLander
				} else {
					let alternativeLander = world.simulate(marsLander: evolvingLander, action: Chromosome.neutralGene.action)
					if world.testLanded(marsLander: alternativeLander) {
						let prefixChromosome = chromosome.prefix(ttl-1)
						chromosome = prefixChromosome
						chromosome.ttl = Chromosome.maxTTL + alternativeLander.fuel
						chromosome.blackBox = alternativeLander
					} else {
						let prefixChromosome = chromosome.prefix(ttl)
						chromosome = prefixChromosome
						chromosome.ttl = ttl
						chromosome.blackBox = nextLander
					}
				}

				return
			}
		}
		fatal("shouldn't be here " + #function + "\(chromosome)")
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

		fitnessScored = false
	}

	mutating func addMutantsWithRandomTailOrHead() {
		let countBeforeMutation = current.count
		for i in 0..<countBeforeMutation {
			let sample = current[i]
			current.append(makeMutant(sample, species: .HeadMutant))
			current.append(makeMutant(sample, species: .TailMutant))
			current.append(makeMutant(sample, species: .BodyMutant))
		}

		fitnessScored = false
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
		sort()
		current = sortedIndexes.prefix(limit).map{ current[$0] }
		fitnessScored = false
	}

	mutating func bestChomosome() -> Chromosome {
		evalTTL()
		sort()
		return current[sortedIndexes[0]]
	}

	mutating func incrementAge(marsLander next: MarsLander) {
		lander = next
		for i in 0..<current.count {
			current[i].incrementAge()
		}

		fitnessScored = false
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