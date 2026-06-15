import SwiftUI

// Explains how watering coco works — you water to runoff and adjust, rather than pre-calculating
// a fixed amount — and warns that a mixed batch doesn't keep. No calculator.
struct MixVolumeSheet: View {
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(spacing: 16) {
						section("drop.fill", "WATER TO RUNOFF",
						        "Water to about 10–20% runoff every time — a little draining from the bottom. That flushes out salts that would otherwise build up and keeps the root-zone EC and pH steady. Testing that runoff is how you'd check them.")
						section("waterbottle.fill", "HOW MUCH PER WATERING",
						        "Coco stays nearly saturated, so each watering just tops it up — roughly 5% of the container is enough to get runoff. If it takes a lot more than that, it dried out too far between waterings: water more OFTEN, not more each time.")
						section("clock.fill", "HOW OFTEN",
						        "Don't water it like soil and wait for it to dry — the surface should never go dry or pale. Water again once it's given up a little moisture: about once a day for seedlings, rising to 3–5× a day in full flower. At \(phase.rawValue), usually \(phase.wateringsPerDayHint).")
						section("arrow.up.bin.fill", "MATCH POT TO PLANT",
						        "A seedling in a big pot stays wet too long and drowns — and would need a huge amount to reach runoff. Start small and pot up as it grows; that's why a seedling only needs a splash.")
						shelfLifeWarning
						Text("So mix a fresh batch for each watering, feed to runoff, then adjust by eye: ran dry before any runoff? mix a bit more. Lots left over or pooling? mix less.")
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
		.presentationDetents([.large])   // open full-height
	}

	private func section(_ icon: String, _ title: String, _ body: String) -> some View {
		VStack(alignment: .leading, spacing: 6) {
			HStack(spacing: 6) {
				Image(systemName: icon).font(.caption).foregroundStyle(Theme.accent)
				Text(title).font(.system(size: 11, weight: .semibold)).tracking(0.8).foregroundStyle(Theme.secondary)
			}
			Text(body).font(.callout).foregroundStyle(Theme.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
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
}

#Preview("Veg II") {
	MixVolumeSheet(phase: .vegetativeII, colorScheme: .dark)
}

#Preview("Peak bloom") {
	MixVolumeSheet(phase: .generativeII, colorScheme: .light)
}
