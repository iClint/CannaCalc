import SwiftUI

// Where a chosen feed EC sits relative to CANNA's recommended dose for the phase. The tint
// follows: gentle (cyan, weaker) · canna (green, on the chart) · strong (orange, hotter).
enum ECTone {
	case gentle
	case canna
	case strong

	var color: Color {
		switch self {
		case .gentle: return .cyan
		case .canna: return Theme.accent
		case .strong: return .orange
		}
	}
}

// Presentation logic for EC values: formats in the user's chosen unit (mS / ppm) and classifies
// a feed EC against the phase default. Kept free of view state so it's unit-testable.
struct ECFormatter {
	let unit: ECUnit

	// Feed EC within this much of the phase default reads as "at CANNA's recommendation".
	static let cannaTolerance = 0.05

	// The numeric part only, in the chosen unit (e.g. "2.20" for mS, "1100" for ppm).
	func number(_ mS: Double) -> String {
		String(format: "%.\(unit.decimalPlaces)f", unit.convert(mS))
	}

	// Number plus the short unit label (e.g. "2.20 mS").
	func value(_ mS: Double) -> String { "\(number(mS)) \(unit.short)" }

	// Classify a feed EC relative to CANNA's recommended EC for the phase.
	func tone(_ ec: Double, phase: GrowthPhase) -> ECTone {
		let recommended = CannaCoco.defaultEC(phase)
		if abs(ec - recommended) < Self.cannaTolerance { return .canna }
		return ec < recommended ? .gentle : .strong
	}

	func tint(_ ec: Double, phase: GrowthPhase) -> Color { tone(ec, phase: phase).color }
}
