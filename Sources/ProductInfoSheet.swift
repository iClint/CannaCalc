import SwiftUI

// Per-product reference: what a bottle is, how/when to use it, whether it's optional, and its
// per-phase usage — with the current phase highlighted and a contextual "right now" line.
struct ProductInfoSheet: View {
	let product: FeedProduct
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						header
						purposeCard
						usageCard
						nowCallout
					}
					.padding(16)
				}
			}
			.navigationTitle("Product")
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

	private var header: some View {
		HStack(spacing: 10) {
			Text(product.rawValue).font(.title3.weight(.bold)).foregroundStyle(Theme.primary)
			Spacer()
			tag(product.isCore ? "BASE" : "OPTIONAL", product.isCore ? Theme.accent : Theme.secondary)
		}
	}

	private var purposeCard: some View {
		VStack(alignment: .leading, spacing: 8) {
			label("WHAT IT'S FOR")
			Text(product.purpose).font(.callout).foregroundStyle(Theme.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}

	@ViewBuilder
	private var usageCard: some View {
		VStack(alignment: .leading, spacing: 8) {
			label("WHEN IT'S USED")
			if product == .calMag {
				Text("Dosed every feed, set by your source-water EC rather than the growth phase — full strength (~1.1 ml/L) for 0-EC water, tapering to none once your water reaches ~0.4 mS/cm.")
					.font(.callout).foregroundStyle(Theme.primary)
					.fixedSize(horizontal: false, vertical: true)
			} else {
				VStack(spacing: 0) {
					ForEach(Array(GrowthPhase.allCases.enumerated()), id: \.element.id) { idx, p in
						usageRow(p)
						if idx < GrowthPhase.allCases.count - 1 { Divider().overlay(Theme.cardStroke) }
					}
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}

	private func usageRow(_ p: GrowthPhase) -> some View {
		let dose = p.dose(of: product) ?? 0
		let isNow = p == phase
		return HStack {
			Text(p.rawValue)
				.font(.subheadline.weight(isNow ? .bold : .regular))
				.foregroundStyle(isNow ? Theme.accent : Theme.primary)
			Spacer()
			if dose > 0.001 {
				Text(String(format: "%.1f ml/L", dose))
					.font(.subheadline.monospacedDigit())
					.foregroundStyle(isNow ? Theme.accent : Theme.secondary)
			} else {
				Text("—").font(.subheadline).foregroundStyle(Theme.secondary.opacity(0.5))
			}
		}
		.padding(.vertical, 7).padding(.horizontal, 8)
		.background(isNow ? Theme.accent.opacity(0.10) : .clear,
		            in: RoundedRectangle(cornerRadius: 8, style: .continuous))
	}

	private var nowCallout: some View {
		let dose = phase.dose(of: product) ?? 0
		let lead: String = product == .calMag
			? "Now: depends on your source water"
			: (dose > 0.001 ? "Now (\(phase.rawValue)): \(String(format: "%.1f", dose)) ml/L"
			                : "Now (\(phase.rawValue)): not used")
		return HStack(alignment: .top, spacing: 8) {
			Image(systemName: "info.circle.fill").foregroundStyle(Theme.accent)
			Text("\(lead) — \(product.usageNote(at: phase))")
				.font(.caption).foregroundStyle(Theme.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(14)
		.background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
	}

	private func label(_ text: String) -> some View {
		Text(text).font(.system(size: 11, weight: .semibold)).tracking(0.8)
			.foregroundStyle(Theme.secondary)
	}

	private func tag(_ text: String, _ color: Color) -> some View {
		Text(text).font(.caption2.weight(.bold)).foregroundStyle(color)
			.padding(.horizontal, 8).padding(.vertical, 3)
			.background(color.opacity(0.14), in: Capsule())
	}
}

#Preview("Rhizotonic – tapering") {
	ProductInfoSheet(product: .rhizotonic, phase: .generativeI, colorScheme: .dark)
}

#Preview("Cal-Mag") {
	ProductInfoSheet(product: .calMag, phase: .vegetativeII, colorScheme: .dark)
}

#Preview("Coco A – base") {
	ProductInfoSheet(product: .cocoA, phase: .vegetativeII, colorScheme: .light)
}
