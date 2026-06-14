import SwiftUI

// Root feed screen: owns the phase / target-EC state, computes the recipe, and composes the
// header, phase summary, inputs, and recipe cards. Each card lives in its own file.
struct CalculatorView: View {
	@ObservedObject private var settings = FeedSettings.shared
	@State private var phase: GrowthPhase = .vegetativeII
	// Target feed EC (total mS/cm) the recipe makes; the A&B dose is back-solved to hit it.
	@State private var targetEC: Double = CannaCoco.defaultEC(.vegetativeII)
	@State private var showPhasePicker = false
	@State private var showSettings = false
	@State private var showDisclaimer = false

	// `initialPhase` lets previews open the screen on a specific phase (e.g. harvest); the app
	// uses the default. targetEC tracks the phase's CANNA-recommended EC, same as the .onChange.
	init(initialPhase: GrowthPhase = .vegetativeII) {
		_phase = State(initialValue: initialPhase)
		_targetEC = State(initialValue: CannaCoco.defaultEC(initialPhase))
	}

	private var recipe: Recipe {
		CannaCoco.recipe(phase: phase, volumeL: settings.volume, waterEC: settings.baseEC,
		                 targetEC: targetEC, owned: settings.ownedProducts)
	}
	private var formatter: ECFormatter { ECFormatter(unit: settings.ecUnit) }

	var body: some View {
		ZStack {
			Theme.bg.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 14) {
					HeaderBar { showSettings = true }
					PhaseSummaryCard(phase: phase) { showPhasePicker = true }
					if phase.isHarvest {
						HarvestCard()
					} else {
						InputsCard(settings: settings, phase: phase, targetEC: $targetEC,
						           recipe: recipe, formatter: formatter)
						RecipeCard(recipe: recipe, formatter: formatter,
						           ownsCalMag: settings.ownedProducts.contains(.calMag),
						           baseEC: settings.baseEC)
					}
				}
				.padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 24)
			}
		}
		.preferredColorScheme(settings.appTheme.colorScheme)
		.tint(Theme.accent)
		// Each phase opens at CANNA's recommended feed EC.
		.onChange(of: phase) { _, newPhase in targetEC = CannaCoco.defaultEC(newPhase) }
		.sheet(isPresented: $showPhasePicker) {
			PhasePickerSheet(phase: $phase, colorScheme: settings.appTheme.colorScheme)
		}
		.sheet(isPresented: $showSettings) {
			SettingsSheet(settings: settings, colorScheme: settings.appTheme.colorScheme)
		}
		.sheet(isPresented: $showDisclaimer) {
			DisclaimerView(isFirstRun: true, colorScheme: settings.appTheme.colorScheme) { dontShowAgain in
				settings.hasSeenDisclaimer = dontShowAgain
			}
		}
		// Keep the screen awake while mixing — only while the app is foregrounded.
		.keepScreenAwake(settings.keepScreenAwake)
		// Show the disclaimer once, on first launch, until acknowledged.
		.onAppear { if !settings.hasSeenDisclaimer { showDisclaimer = true } }
	}
}

// The main feed screen in each appearance. The app's theme override is `.system` by default
// (preferredColorScheme(nil)), so the injected colorScheme drives the canvas. Tap the gear or
// phase card in an interactive preview to drive the Settings / phase-picker sheets live.
#Preview("Calculator – Light") {
	CalculatorView()
		.environment(\.colorScheme, .light)
}

#Preview("Calculator – Dark") {
	CalculatorView()
		.environment(\.colorScheme, .dark)
}

// Harvest phase swaps the inputs/recipe for the "time to chop" card.
#Preview("Harvest") {
	CalculatorView(initialPhase: .harvest)
		.environment(\.colorScheme, .dark)
}
