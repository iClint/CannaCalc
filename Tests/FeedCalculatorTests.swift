import Testing
@testable import CocoFeed

// CANNA Coco feed logic, built verbatim from the CANNA COCO GROW SCHEDULE (AU, V25.01).
// Per-phase chart doses + CalMag (water-EC driven) + the target-EC band + pH-up headroom.
struct FeedCalculatorTests {
	private func ab(_ r: Recipe) -> Double { r.items.first { $0.name == "CANNA Coco A" }!.mlPerL }
	private func dose(_ r: Recipe, _ name: String) -> Double { r.items.first { $0.name == name }!.mlPerL }
	private func make(_ phase: GrowthPhase, targetEC: Double? = nil, waterEC: Double = 0.4,
	                  volumeL: Double = 1, phHeadroom: Double = 0) -> Recipe {
		CannaCoco.recipe(phase: phase, volumeL: volumeL, waterEC: waterEC, basePH: 6,
		                 targetEC: targetEC ?? CannaCoco.defaultEC(phase), phHeadroom: phHeadroom)
	}

	// MARK: - Per-phase chart doses (ml/L = chart ml/10L ÷ 10)

	@Test func cocoABMatchesChart() {
		#expect(GrowthPhase.startRooting.cocoAB == 2.9)
		#expect(GrowthPhase.vegetativeI.cocoAB == 2.9)
		#expect(GrowthPhase.vegetativeII.cocoAB == 3.3)
		#expect(GrowthPhase.generativeI.cocoAB == 3.3)
		#expect(GrowthPhase.generativeII.cocoAB == 3.3)
		#expect(GrowthPhase.generativeIII.cocoAB == 2.9)
		#expect(GrowthPhase.generativeIV.cocoAB == 0)
		#expect(GrowthPhase.harvest.cocoAB == 0)
	}

	@Test func additiveDosesMatchChart() {
		#expect(GrowthPhase.startRooting.rhizotonic == 4.0)
		#expect(GrowthPhase.vegetativeI.rhizotonic == 2.0)
		#expect(GrowthPhase.generativeI.rhizotonic == 0.5)
		#expect(GrowthPhase.generativeIV.rhizotonic == 0)
		#expect(GrowthPhase.startRooting.cannazym == 0)          // none at rooting
		#expect(GrowthPhase.vegetativeI.cannazym == 2.5)
		#expect(GrowthPhase.generativeIV.cannazym == 2.5)        // flush keeps Cannazym
		#expect(GrowthPhase.startRooting.cannaboost == 0)
		#expect(GrowthPhase.vegetativeII.cannaboost == 2.0)      // Boost from Veg II onward
		#expect(GrowthPhase.generativeIV.cannaboost == 2.0)
	}

	@Test func ecNutritionMatchesChart() {
		#expect(GrowthPhase.startRooting.ecNutrition == 1.6)
		#expect(GrowthPhase.vegetativeII.ecNutrition == 1.8)
		#expect(GrowthPhase.generativeII.ecNutrition == 2.3)     // peak (includes PK)
		#expect(GrowthPhase.generativeIII.ecNutrition == 1.6)
		#expect(GrowthPhase.generativeIV.ecNutrition == 0)
	}

	@Test func pkOnlyInGenerativeII() {
		for phase in GrowthPhase.allCases {
			#expect(phase.pk == (phase == .generativeII ? 1.5 : 0))
		}
	}

	@Test func everyPhaseHasTriggerAndLight() {
		for phase in GrowthPhase.allCases {
			#expect(!phase.trigger.isEmpty)
			#expect(!phase.light.isEmpty)
		}
		#expect(GrowthPhase.startRooting.light == "18 h")
		#expect(GrowthPhase.generativeI.light == "12/12")
		#expect(GrowthPhase.harvest.light == "—")
	}

	// MARK: - Recipe at the CANNA default

	@Test func defaultRecipeMatchesChart() {
		for phase in GrowthPhase.allCases where phase.feedsNutrients {
			let r = make(phase)
			#expect(abs(ab(r) - phase.cocoAB) < 1e-9)                       // A&B at CANNA value
			#expect(dose(r, "CANNA Coco B") == ab(r))                       // A == B
			#expect(abs(r.targetEC - (phase.ecNutrition + 0.4)) < 1e-9)     // total = nutrition + 0.4 water
		}
	}

	@Test func mlScalesWithVolumeRoundedToWhole() {
		let r = make(.vegetativeII, volumeL: 12)
		let a = r.items.first { $0.name == "CANNA Coco A" }!
		#expect(a.ml == (a.mlPerL * 12).rounded())   // 3.3 × 12 = 39.6 → 40
		#expect(a.ml == a.ml.rounded())              // always a whole number
	}

	@Test func mlRoundsToWhole() {
		let r = make(.vegetativeII, waterEC: 0, volumeL: 15)
		#expect(r.items.first { $0.name == "CANNA Coco A" }!.ml == 50)   // 3.3 × 15 = 49.5 → 50
		#expect(r.items.first { $0.name == "Cal-Mag" }!.ml == 17)        // 1.1 × 15 = 16.5 → 17
	}

	// MARK: - Target-EC band (A&B back-solved from the dialled EC, clamped to the safe band)

	@Test func targetECDefaultsToCannaDose() {
		for phase in GrowthPhase.allCases where phase.feedsNutrients {
			#expect(abs(ab(make(phase)) - phase.cocoAB) < 1e-9)   // CANNA default EC → CANNA A&B
		}
	}

	@Test func lowTargetClampsToGentleMin() {
		for phase in GrowthPhase.allCases where phase.feedsNutrients {
			#expect(abs(ab(make(phase, targetEC: 0)) - phase.cocoAB * 0.75) < 1e-9)
		}
	}

	@Test func highTargetClampsToSafeCeiling() {
		for phase in GrowthPhase.allCases where phase.feedsNutrients {
			let r = make(phase, targetEC: 99)
			let upFraction = min(0.25, 2.4 / phase.ecNutrition - 1)
			#expect(abs(ab(r) - phase.cocoAB * (1 + upFraction)) < 1e-9)
			#expect(r.targetEC - 0.4 <= CannaCoco.safeNutritionEC + 1e-9)   // never past the ceiling
		}
	}

	@Test func recipeMakesTheDialledECWithinBand() {
		// Inside the band, the achieved EC equals what the user dialled.
		#expect(abs(make(.vegetativeII, targetEC: 2.0).targetEC - 2.0) < 1e-9)
		#expect(abs(make(.startRooting, targetEC: 1.8).targetEC - 1.8) < 1e-9)
	}

	@Test func phUpHeadroomDosesLowerAndLandsOnTarget() {
		// Veg II, target 1.9 with 0.1 pH-up headroom: A&B dosed for 1.8, mix reads 1.8,
		// final aim returns to 1.9 (the +0.1 pH-up adds back).
		let r = make(.vegetativeII, targetEC: 1.9, phHeadroom: 0.1)
		#expect(abs(r.mixEC - 1.8) < 1e-9)
		#expect(abs(r.targetEC - 1.9) < 1e-9)
		#expect(abs(ab(r) - CannaCoco.abEach(.vegetativeII, targetEC: 1.8)) < 1e-9)
		#expect(ab(r) < ab(make(.vegetativeII, targetEC: 1.9)))    // lower than the no-headroom dose
		// No headroom → mix equals the target.
		let r0 = make(.vegetativeII, targetEC: 1.9)
		#expect(abs(r0.mixEC - r0.targetEC) < 1e-9)
	}

	@Test func phUpHeadroomIgnoredOnFlush() {
		let r = make(.generativeIV, targetEC: 0.4, phHeadroom: 0.1)
		#expect(ab(r) == 0)
		#expect(abs(r.targetEC - 0.4) < 1e-9)   // flush has no A&B, so nothing to reserve
	}

	@Test func ecRangeAndDefault() {
		#expect(CannaCoco.defaultEC(.startRooting) == 2.0)     // 1.6 nutrition + 0.4 water
		#expect(CannaCoco.defaultEC(.vegetativeII) == 2.2)     // 1.8 + 0.4
		#expect(CannaCoco.defaultEC(.generativeII) == 2.7)     // 2.3 + 0.4 (PK peak)
		let range = CannaCoco.ecRange(.vegetativeII)
		#expect(range.lowerBound < 2.2 && 2.2 < range.upperBound)   // default sits inside the band
	}

	// MARK: - CalMag (water-EC driven, max 1.1 ml/L)

	@Test func calMagFromWaterEC() {
		#expect(abs(CannaCoco.calMag(waterEC: 0.0) - 1.1) < 1e-9)     // pure water → full dose
		#expect(abs(CannaCoco.calMag(waterEC: 0.2) - 0.55) < 1e-9)
		#expect(abs(CannaCoco.calMag(waterEC: 0.4) - 0.0) < 1e-9)     // already at ideal
		#expect(CannaCoco.calMag(waterEC: 0.6) == 0)                  // hard water → none
	}

	@Test func calMagAppearsInRecipe() {
		#expect(abs(dose(make(.vegetativeII, waterEC: 0.0), "Cal-Mag") - 1.1) < 1e-9)
		#expect(dose(make(.vegetativeII, waterEC: 0.5), "Cal-Mag") == 0)
	}

	// MARK: - Flush & harvest

	@Test func flushIsWaterPlusZymBoost() {
		let r = make(.generativeIV)
		#expect(ab(r) == 0)
		#expect(abs(r.targetEC - 0.4) < 1e-9)
		#expect(dose(r, "CANNA Cannazym") == 2.5)
		#expect(dose(r, "CANNABOOST Accelerator") == 2.0)
	}

	@Test func flushIgnoresTargetEC() {
		#expect(ab(make(.generativeIV, targetEC: 99)) == 0)
		#expect(!GrowthPhase.generativeIV.feedsNutrients)
	}

	@Test func harvestHasNoRecipe() {
		#expect(GrowthPhase.harvest.isHarvest)
		#expect(!GrowthPhase.harvest.feedsNutrients)
		#expect(make(.harvest).targetEC == 0)
		#expect(make(.harvest).items.allSatisfy { $0.mlPerL == 0 })
	}

	// MARK: - pH guidance (5.5–6.2)

	@Test func phNoteDirection() {
		func note(_ ph: Double) -> String {
			CannaCoco.recipe(phase: .vegetativeII, volumeL: 1, waterEC: 0.4, basePH: ph,
			                 targetEC: CannaCoco.defaultEC(.vegetativeII)).phNote
		}
		#expect(note(7.0).contains("Lower"))
		#expect(note(5.0).contains("Raise"))
		#expect(note(6.0) == "In range")
	}
}
