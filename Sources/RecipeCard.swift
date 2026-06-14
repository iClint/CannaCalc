import SwiftUI

// The mixed recipe: per-product doses, the aim EC / pH-target summary, and mix-order guidance.
struct RecipeCard: View {
	let recipe: Recipe
	let formatter: ECFormatter
	let ownsCalMag: Bool
	let baseEC: Double

	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("RECIPE")
				.font(.system(size: 11, weight: .semibold)).tracking(0.8)
				.foregroundStyle(Theme.secondary)

			VStack(spacing: 0) {
				ForEach(Array(recipe.items.enumerated()), id: \.element.id) { idx, item in
					itemRow(item)
					if idx < recipe.items.count - 1 { Divider().overlay(Theme.cardStroke) }
				}
			}

			Divider().overlay(Theme.cardStroke)
			summaryRow("Aim EC", formatter.value(recipe.targetEC), note: "total")
			summaryRow("pH target",
			           String(format: "%.1f–%.1f", recipe.phTarget.lowerBound, recipe.phTarget.upperBound),
			           note: "ideal 5.8")

			VStack(alignment: .leading, spacing: 4) {
				Text(ownsCalMag
					? "Mix order: CalMag first → confirm water reads ~0.4 mS/cm → A → B → Rhizotonic → Cannazym → CannaBoost → PK → pH last."
					: "Mix order: A → B → Rhizotonic → Cannazym → CannaBoost → PK → pH last.")
				if ownsCalMag && baseEC < CannaCoco.idealWaterEC {
					Text("Add CalMag to the raw water and verify it reads ~0.4 mS/cm before adding A&B.")
						.foregroundStyle(Theme.accent.opacity(0.9))
				}
			}
			.font(.caption2).foregroundStyle(Theme.secondary).padding(.top, 2)
		}
		.padding(16)
		.glassCard()
	}

	private func itemRow(_ item: RecipeItem) -> some View {
		let active = item.mlPerL > 0.001
		return HStack {
			Text(item.name).font(.subheadline.weight(.medium))
				.foregroundStyle(active ? Theme.primary : Theme.secondary.opacity(0.45))
			Spacer()
			if active {
				Text(String(format: "%.1f ml/L", item.mlPerL))
					.font(.caption.monospacedDigit()).foregroundStyle(Theme.secondary)
				Text("\(Int(item.ml)) ml")
					.font(.subheadline.weight(.bold).monospacedDigit())
					.foregroundStyle(Theme.accent)
					.frame(width: 78, alignment: .trailing)
			} else {
				Text("—").font(.subheadline.weight(.medium))
					.foregroundStyle(Theme.secondary.opacity(0.4))
					.frame(width: 78, alignment: .trailing)
			}
		}
		.padding(.vertical, 9)
	}

	private func summaryRow(_ title: String, _ value: String, note: String) -> some View {
		HStack {
			Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
			Spacer()
			Text(note).font(.caption).foregroundStyle(Theme.accent)
			Text(value).font(.subheadline.weight(.bold).monospacedDigit())
				.foregroundStyle(Theme.primary).frame(width: 78, alignment: .trailing)
		}
		.padding(.vertical, 4)
	}
}

#Preview {
	RecipeCard(recipe: CannaCoco.recipe(phase: .generativeII, volumeL: 15, waterEC: 0.2, targetEC: 2.7),
	           formatter: ECFormatter(unit: .mS), ownsCalMag: true, baseEC: 0.2)
		.padding()
		.frame(maxWidth: .infinity)
		.background(Theme.bg)
}
