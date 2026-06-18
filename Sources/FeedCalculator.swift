import Foundation

// CANNA Coco feed calculator, built verbatim from the official CANNA COCO GROW SCHEDULE
// (Australia, V25.01). Every per-phase number is the chart's — Coco A&B, the additive
// doses, and the EC. Each phase carries a brief, CANNA-aligned `summary` plus a plain-language
// `detail` (the in-app tooltip) so a beginner can tell which stage their plant is in.
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

	// Brief, CANNA-aligned description of the stage — shown on the phase card and picker.
	var summary: String {
		switch self {
		case .startRooting:
			return "Seedlings or fresh cuttings settling in and growing roots."
		case .vegetativeI:
			return "Leafy growth under 18 h light, building the plant's frame."
		case .vegetativeII:
			return "Switch to 12/12 light to trigger flowering."
		case .generativeI:
			return "Early bloom — the plant stretches and sets its first flowers."
		case .generativeII:
			return "Peak bloom — the short PK 13/14 boost, about 3 weeks before harvest."
		case .generativeIII:
			return "Flowers fill out and gain weight after the PK boost."
		case .generativeIV:
			return "Final ripening — flush with plain feed, no base nutrients."
		case .harvest:
			return "Ripe and ready to cut."
		}
	}

	// Plain-language, beginner-friendly detail (the tooltip), following CANNA's grow guide.
	var detail: String {
		switch self {
		case .startRooting:
			return "The first week or two: roots are taking hold and top growth is slow. Feed gently and use Rhizotonic to build a strong root system under 18 hours of light. Move on once you see active new leaves."
		case .vegetativeI:
			return "Under 18 h light the plant photosynthesises hard and stacks up the leaves and stems it needs to flower. Feed full Coco A&B with Rhizotonic and Cannazym. This stage can run 1–4 weeks depending on the size you want."
		case .vegetativeII:
			return "Once the plant has filled out, drop the lights to 12 hours on / 12 off to tell it to start flowering. Keep feeding at full strength; some varieties take up to 4 weeks to make the switch."
		case .generativeI:
			return "After the light switch the plant stretches and forms its first flowers, shifting energy from leaves to bloom. CannaBoost comes in here to support flowering."
		case .generativeII:
			return "About 3 weeks before harvest, once the stretch has stopped and buds are swelling, add PK 13/14 for 3–6 days only to drive flower development. Too early can block Cal-Mag uptake; too long can affect flavour."
		case .generativeIII:
			return "The PK boost is done. Ease the base feed back slightly while the flowers keep gaining density and weight. Keep Coco A&B, Cannazym and CannaBoost going."
		case .generativeIV:
			return "The last 1–2 weeks. Stop the base A&B and flush with pH'd water (around 5.5–6.2), leaving only Cannazym/CannaBoost, to rinse stored salts and improve the final taste."
		case .harvest:
			return "Flowering is complete. Give a final flush of plain water if you haven't already, check ripeness, then harvest. No feeding at this stage."
		}
	}

	// Rough, typical length of the stage — a planning guide only. Real timing is strain- and
	// grower-dependent (these phases are chosen by what the plant is doing, not the calendar).
	var roughLength: String {
		switch self {
		case .startRooting: return "1–2 wk"
		case .vegetativeI: return "2–6 wk"
		case .vegetativeII: return "~1 wk"
		case .generativeI: return "2–3 wk"
		case .generativeII: return "~1 wk"
		case .generativeIII: return "2–3 wk"
		case .generativeIV: return "1–2 wk"
		case .harvest: return "—"
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

	// Per-phase ml/L for a bottle, mirroring the recipe's dose map so the product info table
	// can't drift from the recipe. CalMag is water-EC driven (not phase-based) → nil, so callers
	// render its special explanation instead of a per-phase number. A & B use the chart default.
	func dose(of product: FeedProduct) -> Double? {
		switch product {
		case .cocoA, .cocoB: return cocoAB
		case .rhizotonic:    return rhizotonic
		case .cannazym:      return cannazym
		case .cannaboost:    return cannaboost
		case .pk:            return pk
		case .calMag:        return nil
		}
	}
}

struct RecipeItem: Identifiable {
	let id = UUID()
	let name: String
	let mlPerL: Double
	let ml: Double
}

// The bottles a grower can dose. Coco A & B are the required base; the rest are optional
// additives the grower toggles on/off by what they actually own. CalMag leads the lineup —
// it's mixed first to bring source water to CANNA's 0.4 mS/cm starting EC.
enum FeedProduct: String, CaseIterable, Identifiable {
	case calMag = "Cal-Mag"
	case cocoA = "CANNA Coco A"
	case cocoB = "CANNA Coco B"
	case rhizotonic = "CANNA Rhizotonic"
	case cannazym = "CANNA Cannazym"
	case cannaboost = "CANNABOOST Accelerator"
	case pk = "CANNA PK 13/14"

	var id: String { rawValue }
	// Coco A & B are the base feed and are always part of the mix.
	var isCore: Bool { self == .cocoA || self == .cocoB }
	var isOptional: Bool { !isCore }
	// Optional bottles the grower may or may not own, in mix order.
	static var optional: [FeedProduct] { allCases.filter { !$0.isCore } }

	// What the bottle is, when/how to use it, and whether it's optional — reference copy for the
	// product info sheet, grounded in CANNA's stated product roles.
	var purpose: String {
		switch self {
		case .calMag:
			return "Calcium/magnesium supplement. Soft, RO or rainwater starts near 0 EC and lacks the calcium and magnesium the plant needs. Add Cal-Mag FIRST, before the base nutrients, to bring your source water up to CANNA's ideal ~0.4 mS/cm starting point. The dose is set by your water, not the growth phase: softer water needs more (up to ~1.1 ml/L at 0 EC), and hard water already at or above 0.4 mS/cm needs none. Optional — skip it if your tap water already reads ~0.4 mS/cm or higher."
		case .cocoA:
			return "Part A of CANNA's two-part Coco base nutrient — the core feed that supplies most of what the plant eats through every growing phase, always dosed alongside Coco B at the same amount. Add A to the water first and stir, THEN add B — never mix the A and B concentrates directly (that locks up calcium). This is the required base, not optional."
		case .cocoB:
			return "Part B of CANNA's two-part Coco base nutrient, dosed at the same amount as Coco A. The two halves are kept apart on purpose: combining the concentrates makes nutrients precipitate and drop out. Always add B to the water AFTER A is already mixed in. This is the required base, not optional."
		case .rhizotonic:
			return "Root stimulant and vitality booster — it drives vigorous root growth and improves resistance to stress and disease, most valuable on seedlings, cuttings and young plants. Used heaviest at rooting and early veg, then tapered right down and dropped before the bloom flush. Optional, and worth most early; by late flower it's barely used, so running out near the end matters little."
		case .cannazym:
			return "Enzyme additive that breaks down dead root material into nutrients the plant can reuse, keeping the root zone clean. Especially useful if you REUSE coco — double the dose (about 5 ml/L) on reused substrate. Used through veg and bloom including the flush; not at rooting or harvest. Optional."
		case .cannaboost:
			return "CANNABOOST Accelerator — a flowering and yield enhancer that lifts the plant's metabolism so buds develop faster, fuller and tastier. Comes in from the flip to flower (Vegetative II) and runs all the way through the flush. Optional, but a popular bloom booster."
		case .pk:
			return "PK 13/14 — a concentrated phosphorus + potassium bud booster for the peak of flowering. Use it for a SHORT window only: about 3 weeks before harvest, for 3–6 days, once the stretch has stopped and buds are swelling. Too early can block Cal-Mag uptake; too long can hurt flavour. Optional, and only ever used in that one short PK week."
		}
	}

	// Phase-aware one-liner describing where this bottle sits in its schedule — derived from the
	// dose curve so it always matches the chart. CalMag is water-driven, not phase-based.
	func usageNote(at phase: GrowthPhase) -> String {
		if self == .calMag {
			return "Set by your source-water EC, not the growth phase — see above."
		}
		let doses = GrowthPhase.allCases.map { $0.dose(of: self) ?? 0 }
		guard let i = GrowthPhase.allCases.firstIndex(of: phase) else { return "" }
		let now = doses[i]
		let earlierMax = doses[..<i].max() ?? 0
		let moreLater = doses[(i + 1)...].contains { $0 > 0 }

		if now == 0 {
			return earlierMax > 0 ? "already dropped for this stage." : "not used at this stage."
		}
		if !moreLater { return "this is its last stage — dropped from here on." }
		if now < earlierMax { return "tapering down, and dropped in a later stage." }
		return "in active use at this stage."
	}
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

	// The achievable TARGET-EC range for a phase (the A&B band mapped to total EC). Bounds are
	// rounded INWARD to 0.05 — low end up, high end down — so every slider stop is an EC the band
	// can actually hit; rounding outward would promise an unreachable value at the ends (e.g. a
	// 2.7 cap on a phase that maxes at 2.65). Falls back to ±0.05 if the band collapses.
	static func ecRange(_ phase: GrowthPhase) -> ClosedRange<Double> {
		let band = abBand(phase)
		let lo = (ecForAB(phase, band.min) * 20).rounded(.up) / 20
		let hi = (ecForAB(phase, band.max) * 20).rounded(.down) / 20
		return lo < hi ? lo...hi : (lo - 0.05)...(lo + 0.05)
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
	                   basePH: Double = 5.8, targetEC: Double, phHeadroom: Double = 0,
	                   owned: Set<FeedProduct> = Set(FeedProduct.allCases)) -> Recipe {
		let headroom = phase.feedsNutrients ? phHeadroom : 0
		let abEach = abEach(phase, targetEC: targetEC - headroom)
		let calmag = calMag(waterEC: waterEC)
		let mixEC = ecForAB(phase, abEach)     // meter reading when mixed, before pH adjustment
		let totalEC = mixEC + headroom         // final EC after pH-up (== targetEC within band)

		// Per-product dose (ml/L). CalMag leads so the water hits 0.4 mS/cm before the base goes in.
		let doses: [FeedProduct: Double] = [
			.calMag: calmag,
			.cocoA: abEach,
			.cocoB: abEach,
			.rhizotonic: phase.rhizotonic,
			.cannazym: phase.cannazym,
			.cannaboost: phase.cannaboost,
			.pk: phase.pk,
		]
		// Keep CANNA's mix order (CalMag → A → B → …) and drop any bottle the grower doesn't own.
		// Per-item ml rounded to whole numbers so it's measurable; ml/L stays precise (EC math
		// is off ml/L, not these rounded mls).
		let items = FeedProduct.allCases
			.filter { $0.isCore || owned.contains($0) }
			.map { product -> RecipeItem in
				let mlPerL = doses[product] ?? 0
				return RecipeItem(name: product.rawValue, mlPerL: mlPerL, ml: (mlPerL * volumeL).rounded())
			}

		let phBand = String(format: "%.1f–%.1f", phTarget.lowerBound, phTarget.upperBound)
		let phNote: String
		if basePH > phTarget.upperBound { phNote = "Lower to \(phBand) with pH Down" }
		else if basePH < phTarget.lowerBound { phNote = "Raise to \(phBand) with pH Up" }
		else { phNote = "In range" }

		return Recipe(items: items, targetEC: totalEC, mixEC: mixEC, phTarget: phTarget, phNote: phNote)
	}
}
