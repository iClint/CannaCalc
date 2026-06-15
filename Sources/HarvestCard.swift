import SwiftUI

// Shown for the harvest phase in place of the inputs/recipe — there's no feed, just the chop cue.
struct HarvestCard: View {
	var body: some View {
		VStack(spacing: 12) {
			Image(systemName: "scissors")
				.font(.system(size: 34)).foregroundStyle(Theme.accent)
				.shadow(color: Theme.accent.opacity(0.5), radius: 8)
			Text("Time to chop").font(.headline.weight(.bold)).foregroundStyle(Theme.primary)
			Text(GrowthPhase.harvest.detail)
				.font(.subheadline).foregroundStyle(Theme.secondary)
				.multilineTextAlignment(.center)
			Text("No feed — harvest after any final flush.")
				.font(.caption2).foregroundStyle(Theme.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding(20)
		.glassCard()
	}
}

#Preview {
	HarvestCard()
		.padding()
		.background(Theme.bg)
}
