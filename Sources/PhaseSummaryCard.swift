import SwiftUI

// Compact current-phase card. The whole card is tappable to open the phase picker; the info
// button sits on top and catches its own tap to open the stage guide instead.
struct PhaseSummaryCard: View {
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	let onTap: () -> Void
	@State private var showGuide = false

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack(spacing: 10) {
				Image(systemName: "leaf.fill")
					.font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.accent)
					.frame(width: 30, height: 30)
					.background(Theme.accent.opacity(0.16), in: Circle())
				VStack(alignment: .leading, spacing: 1) {
					Text("GROWTH PHASE")
						.font(.system(size: 10, weight: .semibold)).tracking(0.5)
						.foregroundStyle(Theme.secondary)
					Text(phase.rawValue).font(.headline.weight(.bold)).foregroundStyle(Theme.primary)
				}
				Spacer()
				LightBadge(light: phase.light)
				infoButton
				Image(systemName: "chevron.up.chevron.down")
					.font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
			}
			Text(phase.summary)
				.font(.caption2).foregroundStyle(Theme.secondary)
				.fixedSize(horizontal: false, vertical: true)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding(14)
		.glassCard()
		// Whole card opens the picker; the info button above catches its own tap.
		.contentShape(Rectangle())
		.onTapGesture { onTap() }
		.sheet(isPresented: $showGuide) {
			PhaseGuideSheet(phase: phase, colorScheme: colorScheme)
		}
	}

	// Layered on top of the card — a big, obvious tap target that opens the stage guide.
	private var infoButton: some View {
		Button { showGuide = true } label: {
			Image(systemName: "info.circle.fill")
				.font(.title2).foregroundStyle(Theme.accent)
				.frame(width: 34, height: 34)
				.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	PhaseSummaryCard(phase: .vegetativeII, colorScheme: .dark, onTap: {})
		.padding()
		.background(Theme.bg)
}
