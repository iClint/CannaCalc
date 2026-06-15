import SwiftUI

// "How much to mix?" — a rough guide that sizes the recipe batch from plant count, pot size and
// the current phase's daily water use. Not a watering schedule; the grower trues it up by runoff.
struct MixVolumeSheet: View {
	@ObservedObject var settings: FeedSettings
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	private var perWatering: Double {
		CannaCoco.suggestedWateringVolume(plants: settings.plantCount, potVolumeL: settings.potVolumeL)
	}
	private var perPlant: Double { settings.potVolumeL * CannaCoco.wateringFractionToRunoff }

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(spacing: 16) {
						plantsCard
						potCard
						resultCard
						shelfLifeWarning
						Text("Coco is watered to ~10–20% runoff to keep it moist and flush salts, so this is **per watering** — set by the container size, not the plant's drink. At **\(phase.rawValue)** you'd typically water **\(phase.wateringsPerDayHint)**; mix a fresh batch each time and adjust to your actual runoff.")
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
		.presentationDetents([.large])   // open full-height, not a half sheet
	}

	// Mixed feed doesn't keep — warn against over-mixing.
	private var shelfLifeWarning: some View {
		HStack(alignment: .top, spacing: 10) {
			Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
			Text("Mix only what you'll use within ~24 hours. A standing batch drifts in pH and its organic/enzyme additives (Rhizotonic, Cannazym, CannaBoost) break down — don't keep it more than a day or two.")
				.font(.caption2).foregroundStyle(Theme.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(14)
		.background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
		.overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.orange.opacity(0.35)))
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
			Text("MIX PER WATERING")
				.font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(Theme.secondary)
			Text("\(Int(perWatering)) L")
				.font(.system(size: 38, weight: .bold).monospacedDigit()).foregroundStyle(Theme.accent)
			Text("≈ \(String(format: "%.1f", perPlant)) L per plant, to ~10–20% runoff")
				.font(.caption).foregroundStyle(Theme.secondary)
				.multilineTextAlignment(.center)
			Button {
				settings.volume = perWatering
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
