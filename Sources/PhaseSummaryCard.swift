import SwiftUI

// Compact current-phase card. Tapping the upper area opens the phase picker; the prominent
// "What is this stage?" button opens the full guide sheet.
struct PhaseSummaryCard: View {
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	let onTap: () -> Void
	@State private var showGuide = false

	var body: some View {
		VStack(alignment: .leading, spacing: 10) {
			// Tap the phase area to change phase.
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
					Text(phase.summary)
						.font(.caption2).foregroundStyle(Theme.secondary)
						.fixedSize(horizontal: false, vertical: true)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
			}
			.buttonStyle(.plain)

			guideButton
		}
		.padding(14)
		.glassCard()
		.sheet(isPresented: $showGuide) {
			PhaseGuideSheet(phase: phase, colorScheme: colorScheme)
		}
	}

	// Prominent, labelled control — the in-depth, beginner-friendly stage guide.
	private var guideButton: some View {
		Button { showGuide = true } label: {
			HStack(spacing: 7) {
				Image(systemName: "info.circle.fill").font(.subheadline)
				Text("What is this stage?").font(.subheadline.weight(.semibold))
				Spacer()
				Image(systemName: "chevron.right").font(.caption2.weight(.bold))
			}
			.foregroundStyle(Theme.accent)
			.padding(.horizontal, 12).padding(.vertical, 9)
			.frame(maxWidth: .infinity)
			.background(Theme.accent.opacity(0.12), in: Capsule())
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	PhaseSummaryCard(phase: .vegetativeII, colorScheme: .dark, onTap: {})
		.padding()
		.background(Theme.bg)
}
