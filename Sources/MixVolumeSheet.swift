import SwiftUI

// "How much to mix?" — a rough guide that sizes the recipe batch from plant count, pot size and
// the current phase's daily water use. Not a watering schedule; the grower trues it up by runoff.
struct MixVolumeSheet: View {
	@ObservedObject var settings: FeedSettings
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	private var perDay: Double {
		CannaCoco.suggestedDailyVolume(phase: phase, plants: settings.plantCount, potVolumeL: settings.potVolumeL)
	}
	private var perPlant: Double { settings.potVolumeL * phase.dailyWaterFractionOfPot }

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(spacing: 16) {
						plantsCard
						potCard
						resultCard
						Text("Rough starting guide for **\(phase.rawValue)** — actual use depends on plant size, light and climate. Split it across your day's waterings and feed each plant to ~10–20% runoff; ran dry early? mix more, lots left over? mix less.")
							.font(.caption2).foregroundStyle(Theme.secondary)
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.padding(16)
				}
			}
			.navigationTitle("How much to mix?")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(colorScheme)
		.presentationDetents([.medium, .large])
	}

	private var plantsCard: some View {
		HStack {
			Text("Plants").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
			Spacer()
			Text("\(settings.plantCount)")
				.font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
			Stepper("", value: $settings.plantCount, in: 1...50).labelsHidden().tint(Theme.accent)
		}
		.padding(16).glassCard()
	}

	private var potCard: some View {
		VStack(spacing: 8) {
			HStack {
				Text("Pot size").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(String(format: "%.0f L", settings.potVolumeL))
					.font(.title3.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
			}
			Slider(value: $settings.potVolumeL, in: 1...50, step: 1).tint(Theme.accent)
			Text("The container they're in right now — a seedling's small cup, not its final pot.")
				.font(.caption2).foregroundStyle(Theme.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding(16).glassCard()
	}

	private var resultCard: some View {
		VStack(spacing: 10) {
			Text("MIX ABOUT")
				.font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(Theme.secondary)
			Text("\(Int(perDay)) L / day")
				.font(.system(size: 38, weight: .bold).monospacedDigit()).foregroundStyle(Theme.accent)
			Text("≈ \(String(format: "%.1f", perPlant)) L per plant today")
				.font(.caption).foregroundStyle(Theme.secondary)
			Button {
				settings.volume = perDay
				dismiss()
			} label: {
				Text("Use as batch volume")
					.font(.subheadline.weight(.bold)).foregroundStyle(Theme.accent)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 11)
					.background(Theme.accent.opacity(0.14), in: Capsule())
			}
			.buttonStyle(.plain)
			.padding(.top, 2)
		}
		.frame(maxWidth: .infinity)
		.padding(18).glassCard()
	}
}

#Preview("Veg II") {
	MixVolumeSheet(settings: .shared, phase: .vegetativeII, colorScheme: .dark)
}

#Preview("Peak bloom") {
	MixVolumeSheet(settings: .shared, phase: .generativeII, colorScheme: .light)
}
