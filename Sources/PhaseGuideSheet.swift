import SwiftUI

// Full explanation of a growth phase, shown as a sheet from the phase card's guide button:
// an illustration, the phase name + light schedule, and the plain-language detail.
struct PhaseGuideSheet: View {
	let phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(spacing: 18) {
						illustration
						VStack(spacing: 6) {
							Text(phase.rawValue)
								.font(.title2.weight(.bold)).foregroundStyle(Theme.primary)
								.multilineTextAlignment(.center)
							HStack(spacing: 5) {
								if phase.light != "—" { Image(systemName: "sun.max.fill") }
								Text(phase.light == "—" ? "No feed" : "Light · \(phase.light)")
							}
							.font(.subheadline.weight(.semibold)).foregroundStyle(Theme.accent)
						}
						Text(phase.detail)
							.font(.body).foregroundStyle(Theme.primary)
							.frame(maxWidth: .infinity, alignment: .leading)
							.fixedSize(horizontal: false, vertical: true)
							.padding(16)
							.glassCard()
					}
					.padding(20)
				}
			}
			.navigationTitle("Stage guide")
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

	// Phase illustration (SF Symbol placeholder — see notes on richer artwork).
	private var illustration: some View {
		Image(systemName: phase.symbol)
			.font(.system(size: 60, weight: .regular))
			.foregroundStyle(Theme.accent)
			.frame(width: 132, height: 132)
			.background(Theme.accent.opacity(0.12), in: Circle())
			.overlay(Circle().strokeBorder(Theme.cardStroke))
			.padding(.top, 8)
	}
}

#Preview("Veg II") {
	PhaseGuideSheet(phase: .vegetativeII, colorScheme: .dark)
}

#Preview("Harvest") {
	PhaseGuideSheet(phase: .harvest, colorScheme: .light)
}
