public struct Chromosome {

	public typealias Action = MarsLander.Action
	public typealias GeneElement = (action: Action, duration: Int)

	public var genes = [Chromosome.neutralGene]
	public var ttl = -1
	public var blackBox: MarsLander?

	static let neutralGene: GeneElement = (Action(rotate: 0, power: 0), Chromosome.maxTTL)
	static let maxTTL = 300
}

public extension Chromosome {

	mutating func incrementAge() {
		genes[0].duration -= 1
		if genes[0].duration < 1 {
			genes.removeFirst()
		}
		if genes.isEmpty {
			genes.insert(Chromosome.neutralGene, atIndex: 0)
			ttl = -1
		} else {
			ttl -= 1
		}
	}

	func prefix(n: Int) -> Chromosome {
		guard n > 0 else { return Chromosome(genes: [Chromosome.neutralGene], ttl: -1, blackBox: nil) }

		var copyLength = 0
		var copyGenes: [GeneElement] = []
		for gene in genes {
			if copyLength + gene.duration >= n {
				copyGenes.append(GeneElement(action: gene.action, duration: n-copyLength))
				break;
			} else {
				copyGenes.append(gene)
				copyLength += gene.duration
			}
		}

		return Chromosome(genes: copyGenes, ttl: -1, blackBox: nil)
	}

	func suffix(from: Int) -> Chromosome {
		var skipped = 0
		var copyGenes: [GeneElement] = []
		for gene in genes {
			if skipped + gene.duration < from {
				skipped += gene.duration
			} else {
				let appendLength = skipped + gene.duration - from
				copyGenes.append(GeneElement(action: gene.action, duration: appendLength))
				skipped = from
			}
		}

		if copyGenes.count == 0 { copyGenes.append(Chromosome.neutralGene) }
		return Chromosome(genes: copyGenes, ttl: -1, blackBox: nil)
	}

	static func combine(head head: Chromosome, tail: Chromosome, at cutPoint: Int) -> Chromosome {
		var copied: [GeneElement] = []
		var headCopiedLength = 0
		for gene in head.genes {
			if gene.duration + headCopiedLength < cutPoint {
				copied.append(gene)
				headCopiedLength += gene.duration
			} else {
				let cutGene = (action: gene.action, duration: cutPoint - headCopiedLength)
				copied.append(cutGene)
				break;
			}
		}

		var tailSkippedLength = 0
		for gene in tail.genes {
			if tailSkippedLength >= cutPoint {
				copied.append(gene)
			} else if tailSkippedLength + gene.duration > cutPoint {
				let cutLength = tailSkippedLength + gene.duration - cutPoint
				let copingGene = (action: gene.action, duration: cutLength)
				copied.append(copingGene)
				tailSkippedLength += cutLength
			} else {
				tailSkippedLength += gene.duration
			}
		}

		return Chromosome(genes: copied, ttl: -1, blackBox: nil)
	}
}

