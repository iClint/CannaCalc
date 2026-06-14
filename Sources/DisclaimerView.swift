import SwiftUI

// Trademark / liability disclaimer. Shown automatically on first run (with a pre-ticked "don't
// show again" toggle that, on Continue, persists the acknowledgement) and reachable any time from
// Settings (where it's reference-only — no toggle, just Done).
struct DisclaimerView: View {
	let isFirstRun: Bool
	let colorScheme: ColorScheme?
	// Called when the first-run user taps Continue; passes whether to stop auto-showing it.
	var onAcknowledge: (_ dontShowAgain: Bool) -> Void = { _ in }

	@Environment(\.dismiss) private var dismiss
	@State private var dontShowAgain = true   // pre-ticked, as requested

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(alignment: .leading, spacing: 16) {
						heading
						affiliationCard
						calculationCard
						if isFirstRun { dontShowAgainToggle }
					}
					.padding(16)
				}
			}
			.navigationTitle("About")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button(isFirstRun ? "Continue" : "Done") {
						if isFirstRun { onAcknowledge(dontShowAgain) }
						dismiss()
					}
					.font(.body.weight(.semibold))
					.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(colorScheme)
		// On first run, force the Continue button so the acknowledgement (and toggle) is captured.
		.interactiveDismissDisabled(isFirstRun)
	}

	private var heading: some View {
		HStack(spacing: 10) {
			Image(systemName: "leaf.circle.fill")
				.font(.largeTitle).foregroundStyle(Theme.accent)
			VStack(alignment: .leading, spacing: 1) {
				Text(AppInfo.name).font(.title2.weight(.bold)).foregroundStyle(Theme.primary)
				Text(AppInfo.version()).font(.caption.monospacedDigit()).foregroundStyle(Theme.secondary)
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}

	private var affiliationCard: some View {
		card("NOT AFFILIATED WITH CANNA") {
			Text("CannaCalc is an independent tool — not affiliated with, endorsed by, or sponsored by CANNA. \"CANNA\" and all product names are trademarks of their respective owners, used here only to identify the products this calculator doses.")
		}
	}

	private var calculationCard: some View {
		card("CALCULATIONS") {
			Text("Doses follow the published CANNA Coco grow schedule (AU V25.01) and are rounded for easy measuring. They are guidance only — always verify EC and pH with your own meter and adjust to your plants and water. Not professional horticultural advice.")
		}
	}

	private var dontShowAgainToggle: some View {
		Toggle(isOn: $dontShowAgain) {
			Text("Don't show this again")
				.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
		}
		.tint(Theme.accent)
		.padding(16).glassCard()
	}

	private func card<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
		VStack(alignment: .leading, spacing: 8) {
			Text(title).font(.system(size: 11, weight: .semibold)).tracking(0.8)
				.foregroundStyle(Theme.secondary)
			content()
				.font(.callout).foregroundStyle(Theme.primary)
				.fixedSize(horizontal: false, vertical: true)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}
}

#Preview("First run") {
	DisclaimerView(isFirstRun: true, colorScheme: .dark)
}

#Preview("From settings") {
	DisclaimerView(isFirstRun: false, colorScheme: .light)
}
