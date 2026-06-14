import SwiftUI

// Compact current-phase card — tapping it opens the phase picker.
struct PhaseSummaryCard: View {
	let phase: GrowthPhase
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 12) {
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
					Text(phase.light)
						.font(.caption2.weight(.semibold)).foregroundStyle(Theme.accent)
						.padding(.horizontal, 8).padding(.vertical, 3)
						.background(Theme.accent.opacity(0.14), in: Capsule())
					Image(systemName: "chevron.up.chevron.down")
						.font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
				}
				Text(phase.trigger)
					.font(.caption2).foregroundStyle(Theme.secondary)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(14)
			.glassCard()
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	PhaseSummaryCard(phase: .vegetativeII, onTap: {})
		.padding()
		.background(Theme.bg)
}
