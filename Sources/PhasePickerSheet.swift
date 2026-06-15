import SwiftUI

// Full-list phase picker, presented as a sheet. Selecting a phase updates the binding and
// dismisses. `colorScheme` carries the app's forced appearance into the sheet hierarchy.
struct PhasePickerSheet: View {
	@Binding var phase: GrowthPhase
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 8) {
					ForEach(GrowthPhase.allCases) { phaseCard($0) }
				}
				.padding(16)
			}
			.background(Theme.bg.ignoresSafeArea())
			.navigationTitle("Growth phase")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(colorScheme)
	}

	private func phaseCard(_ candidate: GrowthPhase) -> some View {
		let selected = candidate == phase
		return Button {
			phase = candidate
			dismiss()
		} label: {
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 8) {
					Text(candidate.rawValue).font(.subheadline.weight(.bold))
						.foregroundStyle(selected ? Theme.accent : Theme.primary)
					Spacer()
					LightBadge(light: candidate.light, tint: selected ? Theme.accent : Theme.secondary)
				}
				Text(candidate.summary)
					.font(.caption2).foregroundStyle(Theme.secondary)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(12)
			.background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
			.overlay(
				RoundedRectangle(cornerRadius: 14)
					.strokeBorder(selected ? Theme.accent : Theme.cardStroke,
					              lineWidth: selected ? 1.5 : 1)
			)
		}
		.buttonStyle(.plain)
	}
}

#Preview {
	PhasePickerSheet(phase: .constant(.vegetativeII), colorScheme: nil)
}
