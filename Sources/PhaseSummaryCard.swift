import SwiftUI

// Compact current-phase card. Tapping the card opens the phase picker; the ⓘ shows a
// beginner-friendly tooltip with the in-depth description.
struct PhaseSummaryCard: View {
	let phase: GrowthPhase
	let onTap: () -> Void
	@State private var showDetail = false

	var body: some View {
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
		// Whole card opens the picker; the ⓘ button below handles its own tap.
		.contentShape(Rectangle())
		.onTapGesture { onTap() }
	}

	private var infoButton: some View {
		Button { showDetail = true } label: {
			Image(systemName: "info.circle")
				.font(.subheadline).foregroundStyle(Theme.secondary)
		}
		.buttonStyle(.plain)
		.popover(isPresented: $showDetail) {
			VStack(alignment: .leading, spacing: 8) {
				Text(phase.rawValue).font(.subheadline.weight(.bold)).foregroundStyle(Theme.primary)
				Text(phase.detail).font(.callout).foregroundStyle(Theme.primary)
					.fixedSize(horizontal: false, vertical: true)
			}
			.padding(16)
			.frame(width: 280)
			.presentationCompactAdaptation(.popover)   // a real tooltip bubble, even on iPhone
		}
	}
}

#Preview {
	PhaseSummaryCard(phase: .vegetativeII, onTap: {})
		.padding()
		.background(Theme.bg)
}
