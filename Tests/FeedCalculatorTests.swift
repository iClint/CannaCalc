import Testing
import SwiftUI
@testable import CannaCalc

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

	@Test func everyPhaseHasDescriptionsAndLight() {
		for phase in GrowthPhase.allCases {
			#expect(!phase.summary.isEmpty)
			#expect(!phase.detail.isEmpty)
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

	@Test func ecRangeBoundsAreReachable() {
		// Every slider end must be an EC the band can actually hit — no rounding overshoot.
		for phase in GrowthPhase.allCases where phase.feedsNutrients {
			let range = CannaCoco.ecRange(phase)
			#expect(abs(make(phase, targetEC: range.upperBound).targetEC - range.upperBound) < 1e-9)
			#expect(abs(make(phase, targetEC: range.lowerBound).targetEC - range.lowerBound) < 1e-9)
		}
	}

	@Test func vegIIECRangeIsTrueAchievableBand() {
		// The reported case: 1.8-nutrition phase tops out at 2.65, not a rounded-up 2.7.
		let range = CannaCoco.ecRange(.vegetativeII)
		#expect(abs(range.lowerBound - 1.75) < 1e-9)
		#expect(abs(range.upperBound - 2.65) < 1e-9)
	}

	@Test func ecRangeAndDefault() {
		#expect(CannaCoco.defaultEC(.startRooting) == 2.0)     // 1.6 nutrition + 0.4 water
		#expect(CannaCoco.defaultEC(.vegetativeII) == 2.2)     // 1.8 + 0.4
		#expect(CannaCoco.defaultEC(.generativeII) == 2.7)     // 2.3 + 0.4 (PK peak)
		let range = CannaCoco.ecRange(.vegetativeII)
		#expect(range.lowerBound < 2.2 && 2.2 < range.upperBound)   // default sits inside the band
	}

	// MARK: - Suggested batch volume (plants × pot size, to size the recipe)

	@Test func suggestedBatchScalesWithPlantsAndPot() {
		// ~6% of pot per plant for a mid phase: 4 × 11 × 0.06 = 2.64 → 3 L.
		#expect(CannaCoco.suggestedBatchVolume(phase: .vegetativeII, plants: 4, potVolumeL: 11)
			== (4.0 * 11 * 0.06).rounded())
		// Doubling the plants ~doubles the mix.
		#expect(CannaCoco.suggestedBatchVolume(phase: .vegetativeII, plants: 8, potVolumeL: 11)
			== (8.0 * 11 * 0.06).rounded())
	}

	@Test func suggestedBatchClampsToSliderRange() {
		#expect(CannaCoco.suggestedBatchVolume(phase: .generativeII, plants: 50, potVolumeL: 50) == 50)  // capped
		#expect(CannaCoco.suggestedBatchVolume(phase: .startRooting, plants: 1, potVolumeL: 1) == 1)      // floored
	}

	@Test func rootingFeedsLessThanBloomForSameSetup() {
		#expect(CannaCoco.suggestedBatchVolume(phase: .startRooting, plants: 10, potVolumeL: 20)
			< CannaCoco.suggestedBatchVolume(phase: .generativeII, plants: 10, potVolumeL: 20))
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

	// MARK: - Product lineup: ordering & ownership

	private func names(_ r: Recipe) -> [String] { r.items.map(\.name) }

	@Test func coreAndOptionalProductSplit() {
		#expect(FeedProduct.cocoA.isCore)
		#expect(FeedProduct.cocoB.isCore)
		#expect(!FeedProduct.calMag.isCore)
		// Optional products, in mix order, are everything but the base A & B.
		#expect(FeedProduct.optional == [.calMag, .rhizotonic, .cannazym, .cannaboost, .pk])
	}

	@Test func calMagIsTheFirstIngredient() {
		// Soft water → CalMag is dosed and must lead the lineup (it brings water to 0.4 first).
		#expect(names(make(.vegetativeII, waterEC: 0)).first == FeedProduct.calMag.rawValue)
	}

	@Test func defaultRecipeKeepsFullLineupInProductOrder() {
		// Owning everything (the default) yields all bottles in FeedProduct order.
		#expect(names(make(.generativeII)) == FeedProduct.allCases.map(\.rawValue))
	}

	@Test func unownedOptionalProductsAreDropped() {
		let r = CannaCoco.recipe(phase: .vegetativeII, volumeL: 1, waterEC: 0.4,
		                         targetEC: CannaCoco.defaultEC(.vegetativeII),
		                         owned: [.cocoA, .cocoB])
		#expect(names(r) == [FeedProduct.cocoA.rawValue, FeedProduct.cocoB.rawValue])
	}

	@Test func coreBaseAlwaysPresentEvenWhenNotOwned() {
		// Owning nothing still doses the base A & B (they're not optional).
		let r = CannaCoco.recipe(phase: .vegetativeII, volumeL: 1, waterEC: 0.4,
		                         targetEC: CannaCoco.defaultEC(.vegetativeII), owned: [])
		#expect(names(r) == [FeedProduct.cocoA.rawValue, FeedProduct.cocoB.rawValue])
	}

	@Test func ownedSubsetPreservesOrderWithCalMagFirst() {
		let r = CannaCoco.recipe(phase: .generativeII, volumeL: 1, waterEC: 0,
		                         targetEC: CannaCoco.defaultEC(.generativeII),
		                         owned: [.calMag, .pk])
		#expect(names(r) == [FeedProduct.calMag.rawValue, FeedProduct.cocoA.rawValue,
		                     FeedProduct.cocoB.rawValue, FeedProduct.pk.rawValue])
	}

	@Test func excludedProductDosesStillCorrectForOwnedOnes() {
		// Dropping a bottle must not disturb the doses of the bottles that remain.
		let full = make(.generativeII, waterEC: 0)
		let subset = CannaCoco.recipe(phase: .generativeII, volumeL: 1, waterEC: 0,
		                              targetEC: CannaCoco.defaultEC(.generativeII),
		                              owned: [.calMag])
		#expect(dose(subset, "CANNA Coco A") == dose(full, "CANNA Coco A"))
		#expect(dose(subset, "Cal-Mag") == dose(full, "Cal-Mag"))
	}

	// MARK: - App theme

	@Test func appThemeColorSchemeMapping() {
		#expect(AppTheme.system.colorScheme == nil)         // follow the device
		#expect(AppTheme.light.colorScheme == .light)
		#expect(AppTheme.dark.colorScheme == .dark)
	}

	@Test func appThemeLabels() {
		#expect(AppTheme.allCases.map(\.label) == ["System", "Light", "Dark"])
	}

	// MARK: - EC formatting & tone (presentation logic)

	@Test func ecFormatterNumberAndValuePerUnit() {
		#expect(ECFormatter(unit: .mS).number(2.2) == "2.20")        // 2 dp for mS
		#expect(ECFormatter(unit: .mS).value(2.2) == "2.20 mS")
		#expect(ECFormatter(unit: .ppm500).number(2.2) == "1100")    // 0 dp, ×500
		#expect(ECFormatter(unit: .ppm500).value(2.2) == "1100 ppm")
		#expect(ECFormatter(unit: .ppm700).value(1.0) == "700 ppm")
	}

	@Test func ecToneClassifiesAgainstPhaseDefault() {
		let f = ECFormatter(unit: .mS)
		let def = CannaCoco.defaultEC(.vegetativeII)   // 2.2
		#expect(f.tone(def, phase: .vegetativeII) == .canna)         // on the chart
		#expect(f.tone(def - 0.5, phase: .vegetativeII) == .gentle)  // weaker
		#expect(f.tone(def + 0.3, phase: .vegetativeII) == .strong)  // hotter
		// Just inside the tolerance still reads as CANNA.
		#expect(f.tone(def + ECFormatter.cannaTolerance / 2, phase: .vegetativeII) == .canna)
	}

	// MARK: - Identifiable conformance (used by the SwiftUI ForEach lists)

	@Test func identifiableIDsAreStable() {
		#expect(GrowthPhase.vegetativeII.id == GrowthPhase.vegetativeII.rawValue)
		#expect(FeedProduct.calMag.id == FeedProduct.calMag.rawValue)
		#expect(ECUnit.ppm500.id == ECUnit.ppm500.rawValue)
		#expect(AppTheme.dark.id == AppTheme.dark.rawValue)
		let item = make(.vegetativeII).items[0]
		#expect(item.id == item.id)   // RecipeItem carries a stable UUID
	}
}

// FeedSettings persistence, exercised against an isolated UserDefaults suite (never the app's
// real store) so every path — defaults, round-trip, ownership edits, bad data — is covered.
@MainActor
struct FeedSettingsTests {
	// A clean, empty defaults store unique to each test.
	private func freshDefaults(_ suite: String) -> UserDefaults {
		let ud = UserDefaults(suiteName: suite)!
		ud.removePersistentDomain(forName: suite)
		return ud
	}

	@Test func defaultsWhenNothingPersisted() {
		let s = FeedSettings(defaults: freshDefaults("test.defaults"))
		#expect(s.volume == 15)
		#expect(s.baseEC == 0.3)
		#expect(s.ecUnit == .mS)                            // empty → invalid rawValue → default
		#expect(s.appTheme == .system)                      // empty → invalid rawValue → default
		#expect(s.keepScreenAwake == true)
		#expect(s.ownedProducts == Set(FeedProduct.allCases))   // own the full lineup on first launch
		#expect(s.plantCount == 1)
		#expect(s.potVolumeL == 11)
	}

	@Test func scalarSettingsPersistAcrossInstances() {
		let ud = freshDefaults("test.persist")
		let writer = FeedSettings(defaults: ud)
		writer.volume = 22
		writer.baseEC = 0.15
		writer.ecUnit = .ppm700
		writer.appTheme = .dark
		writer.keepScreenAwake = false
		writer.plantCount = 6
		writer.potVolumeL = 20

		let reader = FeedSettings(defaults: ud)   // fresh instance, same store
		#expect(reader.volume == 22)
		#expect(reader.baseEC == 0.15)
		#expect(reader.ecUnit == .ppm700)
		#expect(reader.appTheme == .dark)
		#expect(reader.keepScreenAwake == false)   // exercises the `?? true` false branch on reload
		#expect(reader.plantCount == 6)
		#expect(reader.potVolumeL == 20)
	}

	@Test func setOwnedTogglesAndPersists() {
		let ud = freshDefaults("test.owned")
		let writer = FeedSettings(defaults: ud)
		writer.setOwned(.cannaboost, false)
		#expect(!writer.ownedProducts.contains(.cannaboost))
		writer.setOwned(.cannaboost, true)
		#expect(writer.ownedProducts.contains(.cannaboost))
		writer.setOwned(.pk, false)

		let reader = FeedSettings(defaults: ud)
		#expect(!reader.ownedProducts.contains(.pk))         // removal survived the reload
		#expect(reader.ownedProducts.contains(.cannaboost))  // re-add survived too
	}

	@Test func ownedProductsIgnoresUnknownRawValues() {
		let ud = freshDefaults("test.ownedbad")
		ud.set(["Cal-Mag", "Nonsense Brand"], forKey: "ownedProducts")
		let s = FeedSettings(defaults: ud)
		#expect(s.ownedProducts == [.calMag])   // unknown raw values are dropped, known kept
	}

	@Test func emptyOwnedProductsLoadsAsEmpty() {
		let ud = freshDefaults("test.ownedempty")
		ud.set([String](), forKey: "ownedProducts")   // a saved (empty) array, not "nothing saved"
		let s = FeedSettings(defaults: ud)
		#expect(s.ownedProducts.isEmpty)   // distinct from the first-launch all-owned default
	}

	@Test func disclaimerUnseenByDefaultThenPersistsAcknowledgement() {
		let ud = freshDefaults("test.disclaimer")
		let first = FeedSettings(defaults: ud)
		#expect(first.hasSeenDisclaimer == false)   // first launch → popup should show
		first.hasSeenDisclaimer = true              // user taps Continue with "don't show again"
		let relaunch = FeedSettings(defaults: ud)
		#expect(relaunch.hasSeenDisclaimer == true) // never auto-shows again
	}
}

// AppInfo version formatting, tested against synthetic info dictionaries (no real bundle needed).
struct AppInfoTests {
	@Test func versionShowsMarketingOnly() {
		#expect(AppInfo.version(["CFBundleShortVersionString": "1.0"]) == "v1.0")
	}

	@Test func versionAppendsBuildWhenItDiffers() {
		#expect(AppInfo.version(["CFBundleShortVersionString": "1.0", "CFBundleVersion": "3"]) == "v1.0 (3)")
	}

	@Test func versionHidesBuildWhenSameAsMarketing() {
		#expect(AppInfo.version(["CFBundleShortVersionString": "1.0", "CFBundleVersion": "1.0"]) == "v1.0")
	}

	@Test func versionFallsBackWhenMissing() {
		#expect(AppInfo.version([:]) == "v—")
		#expect(AppInfo.version(nil) == "v—")
	}

	@Test func privacyPolicyURLIsHTTPS() {
		#expect(AppInfo.privacyPolicyURL.scheme == "https")
		#expect(AppInfo.privacyPolicyURL.absoluteString
			== "https://iclint.github.io/PrivayPolicies/cannacalc/")
	}
}
