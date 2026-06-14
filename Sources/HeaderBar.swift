import SwiftUI

// App title row with the Settings button.
struct HeaderBar: View {
	let onSettings: () -> Void

	var body: some View {
		HStack(spacing: 8) {
			Image(systemName: "testtube.2")
				.font(.title3).foregroundStyle(Theme.accent)
				.shadow(color: Theme.accent.opacity(0.6), radius: 6)
			VStack(alignment: .leading, spacing: 1) {
				Text("Feed mix").font(.title2.weight(.bold)).foregroundStyle(Theme.primary)
				Text("CANNA Coco · AU schedule").font(.caption2.weight(.medium)).foregroundStyle(Theme.secondary)
			}
			Spacer()
			Button(action: onSettings) {
				Image(systemName: "gearshape.fill")
					.font(.title3).foregroundStyle(Theme.secondary)
			}
		}
	}
}

#Preview {
	HeaderBar(onSettings: {})
		.padding()
		.background(Theme.bg)
}
