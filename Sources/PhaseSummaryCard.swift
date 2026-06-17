import SwiftUI

// Compact current-phase card. The whole card is tappable to open the phase picker.
struct PhaseSummaryCard: View {
	let phase: GrowthPhase
	let onTap: () -> Void

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
		.contentShape(Rectangle())
		.onTapGesture { onTap() }
	}
}

#Preview {
	PhaseSummaryCard(phase: .vegetativeII, onTap: {})
		.padding()
		.background(Theme.bg)
}
