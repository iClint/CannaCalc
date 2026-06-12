import Foundation

// CANNA Coco feed calculator, built verbatim from the official CANNA COCO GROW SCHEDULE
// (Australia, V25.01). Every per-phase number is the chart's — Coco A&B, the additive
// doses, and the EC. Phases use the grower's own names + "trigger to enter" observations
// so a stage is chosen by what the plant is doing.
//
// The grower feeds CANNA's exact value by default. The feed-EC control moves Coco A&B (and
// EC) DOWN to a gentle minimum (−25%, for a stressed plant) or UP toward a strong maximum,
// capped at a safe coco feed-in ceiling. CalMag is dosed separately from the source-water EC,
// exactly as CANNA prescribes (max 1.1 ml/L lifts 0-EC water to the ideal 0.4 mS/cm).

enum GrowthPhase: String, CaseIterable, Identifiable {
	case startRooting = "Start / rooting"
	case vegetativeI = "Vegetative I"
	case vegetativeII = "Vegetative II"
	case generativeI = "Generative I"
	case generativeII = "Generative II (PK)"
	case generativeIII = "Generative III"
	case generativeIV = "Generative IV (flush)"
	case harvest = "Harvest"

	var id: String { rawValue }

	// "Trigger to ENTER" — what you see in the tent that says it's time for this phase.
	var trigger: String {
		switch self {
		case .startRooting:
			return "Germinated seed (taproot showing) set in substrate / seedling just emerged."
		case .vegetativeI:
			return "Cotyledons open + 1st true-leaf set + active new growth — roots have taken hold."
		case .vegetativeII:
			return "You flip to 12/12 — canopy at pre-flower target (ScrOG ~70–80% full, training set), plant ~½–⅔ final height."
		case .generativeI:
			return "Stretch stops (apex <~5 mm/day for 2–3 days, height plateaued) + white pistil clusters at bud sites + screen ~90% full."
		case .generativeII:
			return "Flower clusters established/elongated + calyxes swelling/stacking; pistils dense, still white; ~3–4 wk pre-finish."
		case .generativeIII:
			return "PK week done; buds denser/heavier; first pistils darkening (orange) on older/lower flowers."
		case .generativeIV:
			return "Trichomes clear → cloudy (loupe); pistils ~50–70% darkened/curling; bud swell plateaus; fans yellowing."
		case .harvest:
			return "Trichomes ~70% cloudy + 20–30% amber (loupe); pistils ~70–90% darkened."
		}
	}

	// Light schedule for the phase (the grower's table).
	var light: String {
		switch self {
		case .startRooting, .vegetativeI: return "18 h"
		case .vegetativeII, .generativeI, .generativeII, .generativeIII: return "12/12"
		case .generativeIV: return "10–12 h"
		case .harvest: return "—"
		}
	}

	// All doses ml/L, verbatim from the AU V25.01 chart (chart is ml/10 L ÷ 10).

	// CANNA Coco A & B, ml/L EACH, at CANNA's recommended (default) strength.
	var cocoAB: Double {
		switch self {
		case .startRooting, .vegetativeI, .generativeIII: return 2.9
		case .vegetativeII, .generativeI, .generativeII: return 3.3
		case .generativeIV, .harvest: return 0
		}
	}

	var rhizotonic: Double {
		switch self {
		case .startRooting: return 4.0
		case .vegetativeI, .vegetativeII: return 2.0
		case .generativeI, .generativeII, .generativeIII: return 0.5
		case .generativeIV, .harvest: return 0
		}
	}

	var cannazym: Double {   // ×2 (→5.0) if substrate is reused
		switch self {
		case .startRooting, .harvest: return 0
		default: return 2.5
		}
	}

	var cannaboost: Double {   // CANNABOOST Accelerator — Veg II through flush
		switch self {
		case .vegetativeII, .generativeI, .generativeII, .generativeIII, .generativeIV: return 2.0
		case .startRooting, .vegetativeI, .harvest: return 0
		}
	}

	// PK 13/14 is intrinsic to the PK week (Generative II) — CANNA adds it 3–4 wk pre-harvest.
	var pk: Double { self == .generativeII ? 1.5 : 0 }

	// CANNA's stated nutrition EC (mS/cm) at the default dose; total = nutrition + 0.4 water.
	var ecNutrition: Double {
		switch self {
		case .startRooting, .vegetativeI, .generativeIII: return 1.6
		case .vegetativeII, .generativeI: return 1.8
		case .generativeII: return 2.3
		case .generativeIV, .harvest: return 0
		}
	}

	var isHarvest: Bool { self == .harvest }
	// Phases that actually dose base nutrients (so the feed-EC band applies). Flush and
	// harvest don't — flush is water + Cannazym/Boost, harvest is a chop.
	var feedsNutrients: Bool { cocoAB > 0 }
}

struct RecipeItem: Identifiable {
	let id = UUID()
	let name: String
	let mlPerL: Double
	let ml: Double
}

struct Recipe {
	let items: [RecipeItem]
	let targetEC: Double                  // final total mS/cm the feed aims for (after any pH-up allowance)
	let mixEC: Double                     // what the meter reads when mixed, BEFORE pH adjustment
	let phTarget: ClosedRange<Double>
	let phNote: String
}

enum CannaCoco {
	static let idealWaterEC = 0.4                          // CANNA's target source-water EC
	static let calMagMaxMlPerL = 1.1                       // chart CalMag row tops at 11 ml/10 L
	static let safeNutritionEC = 2.4                       // safe coco feed-in ceiling (boost cap)
	static let strengthDownFraction = 0.25                 // gentle floor: −25% A&B for stress
	static let phTarget: ClosedRange<Double> = 5.5...6.2   // CANNA coco, ideal ~5.8

	// CalMag dose to lift source water to CANNA's ideal 0.4 mS/cm: full 1.1 ml/L at 0-EC
	// water, tapering to 0 at (or above) 0.4 EC.
	static func calMag(waterEC: Double) -> Double {
		let dose = calMagMaxMlPerL * (idealWaterEC - waterEC) / idealWaterEC
		return min(calMagMaxMlPerL, max(0, dose))
	}

	// The A&B band for a phase: gentle minimum, CANNA default, strong maximum. The strong
	// end is the smaller of +25% or whatever keeps nutrition EC at/under the safe ceiling,
	// so early phases get headroom while the hot PK week barely lifts.
	static func abBand(_ phase: GrowthPhase) -> (min: Double, base: Double, max: Double) {
		let base = phase.cocoAB
		guard phase.feedsNutrients, phase.ecNutrition > 0 else { return (base, base, base) }
		let minAB = base * (1 - strengthDownFraction)
		let upFraction = min(strengthDownFraction, max(0, safeNutritionEC / phase.ecNutrition - 1))
		return (minAB, base, base * (1 + upFraction))
	}

	private static func round1(_ x: Double) -> Double { (x * 10).rounded() / 10 }

	// Total feed EC (mS/cm) for a given A&B dose: nutrition (scales through the chart point)
	// + the 0.4 water contribution. Flush = water only; harvest = nothing.
	static func ecForAB(_ phase: GrowthPhase, _ abEach: Double) -> Double {
		guard phase.feedsNutrients, phase.cocoAB > 0 else { return phase.isHarvest ? 0 : idealWaterEC }
		return phase.ecNutrition * (abEach / phase.cocoAB) + idealWaterEC
	}

	// The achievable TARGET-EC range for a phase (the A&B band mapped to total EC, rounded to
	// 0.1 for a 1-dp slider). Falls back to ±0.1 if the band collapses (non-nutrient phases).
	static func ecRange(_ phase: GrowthPhase) -> ClosedRange<Double> {
		let band = abBand(phase)
		let lo = round1(ecForAB(phase, band.min)), hi = round1(ecForAB(phase, band.max))
		return lo < hi ? lo...hi : (lo - 0.1)...(lo + 0.1)
	}

	// CANNA's recommended total EC for the phase (slider default), to 1 dp.
	static func defaultEC(_ phase: GrowthPhase) -> Double { round1(ecForAB(phase, phase.cocoAB)) }

	// Back-solve the A&B dose to hit a target total EC, clamped to the phase's safe band.
	// Non-nutrient phases (flush/harvest) ignore the target and dose no A&B.
	static func abEach(_ phase: GrowthPhase, targetEC: Double) -> Double {
		guard phase.feedsNutrients, phase.ecNutrition > 0 else { return 0 }
		let band = abBand(phase)
		let raw = phase.cocoAB * (targetEC - idealWaterEC) / phase.ecNutrition
		return min(band.max, max(band.min, raw))
	}

	// `phHeadroom` reserves that many mS of the target for the EC that pH-up adds: the A&B is
	// dosed to (targetEC − headroom) so the feed reaches `targetEC` after pH-up. Only applies
	// to nutrient phases.
	static func recipe(phase: GrowthPhase, volumeL: Double, waterEC: Double,
	                   basePH: Double, targetEC: Double, phHeadroom: Double = 0) -> Recipe {
		let headroom = phase.feedsNutrients ? phHeadroom : 0
		let abEach = abEach(phase, targetEC: targetEC - headroom)
		let calmag = calMag(waterEC: waterEC)
		let mixEC = ecForAB(phase, abEach)     // meter reading when mixed, before pH adjustment
		let totalEC = mixEC + headroom         // final EC after pH-up (== targetEC within band)

		let lineup: [(name: String, mlPerL: Double)] = [
			("CANNA Coco A", abEach),
			("CANNA Coco B", abEach),
			("Cal-Mag", calmag),
			("CANNA Rhizotonic", phase.rhizotonic),
			("CANNA Cannazym", phase.cannazym),
			("CANNABOOST Accelerator", phase.cannaboost),
			("CANNA PK 13/14", phase.pk),
		]
		// Per-item ml rounded to whole numbers so it's measurable; ml/L stays precise (EC math
		// is off ml/L, not these rounded mls).
		let items = lineup.map { RecipeItem(name: $0.name, mlPerL: $0.mlPerL, ml: ($0.mlPerL * volumeL).rounded()) }

		let phBand = String(format: "%.1f–%.1f", phTarget.lowerBound, phTarget.upperBound)
		let phNote: String
		if basePH > phTarget.upperBound { phNote = "Lower to \(phBand) with pH Down" }
		else if basePH < phTarget.lowerBound { phNote = "Raise to \(phBand) with pH Up" }
		else { phNote = "In range" }

		return Recipe(items: items, targetEC: totalEC, mixEC: mixEC, phTarget: phTarget, phNote: phNote)
	}
}
