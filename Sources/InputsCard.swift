import SwiftUI

// Batch inputs: volume (always visible) plus a disclosure that reveals source-water EC and the
// feed-EC control. The feed-EC slider drives `targetEC`; the back-solved recipe is passed in.
struct InputsCard: View {
	@ObservedObject var settings: FeedSettings
	let phase: GrowthPhase
	@Binding var targetEC: Double
	let recipe: Recipe
	let formatter: ECFormatter
	@State private var showDetails = false

	// A&B the recipe actually doses, and the CalMag dose for the current water.
	private var abEach: Double { recipe.items.first { $0.name == FeedProduct.cocoA.rawValue }?.mlPerL ?? 0 }
	private var calMag: Double { CannaCoco.calMag(waterEC: settings.baseEC) }
	private var ownsCalMag: Bool { settings.ownedProducts.contains(.calMag) }
	// Rough batch to mix for this phase from plants × pot size (just to size the recipe).
	private var suggestedVolume: Double {
		CannaCoco.suggestedBatchVolume(phase: phase, plants: settings.plantCount, potVolumeL: settings.potVolumeL)
	}

	var body: some View {
		VStack(spacing: 16) {
			batchVolumeRow
			if showDetails {
				mixSizeSection
				waterECRow
				if phase.feedsNutrients { feedECControl }
			}
		}
		.padding(16)
		.glassCard()
	}

	// Batch volume stays visible; the chevron reveals the source water EC + feed EC controls.
	private var batchVolumeRow: some View {
		VStack(spacing: 6) {
			HStack(spacing: 10) {
				Text("Batch volume").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(String(format: "%.0f L", settings.volume))
					.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
				Button {
					withAnimation(.easeInOut(duration: 0.2)) { showDetails.toggle() }
				} label: {
					Image(systemName: "chevron.down")
						.font(.caption.weight(.bold)).foregroundStyle(Theme.secondary)
						.rotationEffect(.degrees(showDetails ? 180 : 0))
				}
			}
			Slider(value: $settings.volume, in: 1...50, step: 1).tint(Theme.accent)
		}
	}

	// Sizing helper: estimate how much to mix from plants × pot size, then "Use" it as the volume.
	// Just sizes the recipe — not a watering guide; the grower trues it up by runoff.
	private var mixSizeSection: some View {
		VStack(spacing: 10) {
			HStack {
				Text("Plants").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text("\(settings.plantCount)")
					.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
				Stepper("", value: $settings.plantCount, in: 1...50).labelsHidden().tint(Theme.accent)
			}
			VStack(spacing: 6) {
				HStack {
					Text("Pot size").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
					Spacer()
					Text(String(format: "%.0f L", settings.potVolumeL))
						.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
				}
				Slider(value: $settings.potVolumeL, in: 1...50, step: 1).tint(Theme.accent)
			}
			HStack {
				VStack(alignment: .leading, spacing: 1) {
					Text("Suggested mix").font(.caption.weight(.semibold)).foregroundStyle(Theme.primary)
					Text("≈ \(Int(suggestedVolume)) L for \(settings.plantCount) plant\(settings.plantCount == 1 ? "" : "s")")
						.font(.caption2).foregroundStyle(Theme.secondary)
				}
				Spacer()
				Button { settings.volume = suggestedVolume } label: {
					Text("Use").font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
						.padding(.horizontal, 14).padding(.vertical, 7)
						.background(Theme.accent.opacity(0.14), in: Capsule())
				}
				.buttonStyle(.plain)
			}
			Text("Feed each plant to ~10–20% runoff; ran dry first? mix a bit more, lots left? mix less.")
				.font(.caption2).foregroundStyle(Theme.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}

	// Source-water EC drives the CalMag dose (full 1.1 ml/L at 0 EC → 0 at CANNA's ideal 0.4).
	private var waterECRow: some View {
		VStack(spacing: 6) {
			HStack {
				Text("Source water EC").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				if ownsCalMag {
					Text(calMag > 0.001 ? "CalMag \(String(format: "%.1f", calMag)) ml/L" : "no CalMag")
						.font(.caption.weight(.medium)).foregroundStyle(Theme.accent)
				}
				Text(String(format: "%.2f mS", settings.baseEC))
					.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(.cyan)
			}
			Slider(value: $settings.baseEC, in: 0...0.4, step: 0.05).tint(.cyan)
		}
	}

	// Target-EC control: drag the feed EC directly (0.1 steps); the A&B is back-solved to hit
	// it, clamped to the phase's safe band. Range = that phase's gentle…strong EC.
	private var feedECControl: some View {
		let range = CannaCoco.ecRange(phase)
		let recommended = CannaCoco.defaultEC(phase)
		return VStack(spacing: 8) {
			HStack(alignment: .firstTextBaseline) {
				Text("Feed EC").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(formatter.value(recipe.targetEC))
					.font(.subheadline.weight(.bold).monospacedDigit())
					.foregroundStyle(formatter.tint(targetEC, phase: phase))
			}
			Slider(value: $targetEC, in: range, step: 0.05).tint(formatter.tint(targetEC, phase: phase))
			HStack {
				Text(formatter.value(range.lowerBound)).font(.caption2).foregroundStyle(.cyan)
				Spacer()
				Text(abs(targetEC - recommended) < ECFormatter.cannaTolerance
					? "CANNA" : "CANNA \(formatter.value(recommended))")
					.font(.caption2.weight(.semibold)).foregroundStyle(Theme.secondary)
				Spacer()
				Text(formatter.value(range.upperBound)).font(.caption2).foregroundStyle(.orange)
			}
			Text("Coco A&B \(String(format: "%.1f", abEach)) ml/L each — back-solved to hit this EC. Lower for a stressed plant; raise only if runoff EC is stripping and it's thriving.")
				.font(.caption2).foregroundStyle(Theme.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}
}

#Preview {
	InputsCard(settings: .shared, phase: .vegetativeII, targetEC: .constant(2.2),
	           recipe: CannaCoco.recipe(phase: .vegetativeII, volumeL: 15, waterEC: 0.3, targetEC: 2.2),
	           formatter: ECFormatter(unit: .mS))
		.padding()
		.background(Theme.bg)
}
