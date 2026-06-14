import SwiftUI

// Settings: appearance, keep-awake, EC unit, and which products the grower owns. Presented as a
// sheet; `colorScheme` carries the app's forced appearance into the sheet hierarchy.
struct SettingsSheet: View {
	@ObservedObject var settings: FeedSettings
	let colorScheme: ColorScheme?
	@Environment(\.dismiss) private var dismiss
	@State private var showDisclaimer = false

	var body: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(spacing: 16) {
						appearanceCard
						keepAwakeCard
						ecUnitCard
						productsCard
						aboutCard
					}
					.padding(16)
				}
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(colorScheme)
	}

	// Light / dark / system appearance.
	private var appearanceCard: some View {
		card("APPEARANCE", note: "Follow the system light/dark setting, or force one.") {
			Picker("", selection: $settings.appTheme) {
				ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
			}
			.pickerStyle(.segmented)
		}
	}

	// Stop the phone sleeping while a batch is being mixed.
	private var keepAwakeCard: some View {
		VStack(alignment: .leading, spacing: 10) {
			label("DISPLAY")
			Toggle(isOn: $settings.keepScreenAwake) {
				VStack(alignment: .leading, spacing: 2) {
					Text("Keep screen awake")
						.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
					Text("Stops the phone sleeping while the app is open so you can mix the batch.")
						.font(.caption2).foregroundStyle(Theme.secondary)
				}
			}
			.tint(Theme.accent)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}

	private var ecUnitCard: some View {
		card("EC UNIT", note: "How EC is shown throughout the recipe.") {
			Picker("", selection: $settings.ecUnit) {
				ForEach(ECUnit.allCases) { Text($0.rawValue).tag($0) }
			}
			.pickerStyle(.segmented)
		}
	}

	// Toggle the bottles the grower owns; un-owned products are left out of the recipe.
	private var productsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			label("PRODUCTS YOU HAVE")
			Text("Coco A & B are the base. Turn off any bottle you don't own and it's left out of the recipe.")
				.font(.caption2).foregroundStyle(Theme.secondary)
			VStack(spacing: 0) {
				ForEach(Array(FeedProduct.optional.enumerated()), id: \.element.id) { idx, product in
					Toggle(isOn: ownedBinding(product)) {
						Text(product.rawValue)
							.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
					}
					.tint(Theme.accent)
					.padding(.vertical, 7)
					if idx < FeedProduct.optional.count - 1 { Divider().overlay(Theme.cardStroke) }
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}

	// About & disclaimer — opens the same view the first-run popup shows, in reference mode.
	private var aboutCard: some View {
		VStack(alignment: .leading, spacing: 10) {
			label("ABOUT")
			Button { showDisclaimer = true } label: {
				HStack {
					VStack(alignment: .leading, spacing: 2) {
						Text("About & disclaimer")
							.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
						Text(AppInfo.version()).font(.caption2.monospacedDigit()).foregroundStyle(Theme.secondary)
					}
					Spacer()
					Image(systemName: "chevron.right")
						.font(.caption.weight(.bold)).foregroundStyle(Theme.secondary)
				}
			}
			.buttonStyle(.plain)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
		.sheet(isPresented: $showDisclaimer) {
			DisclaimerView(isFirstRun: false, colorScheme: colorScheme)
		}
	}

	// A titled glass card with a caption under the supplied control.
	private func card<Content: View>(_ title: String, note: String,
	                                  @ViewBuilder content: () -> Content) -> some View {
		VStack(alignment: .leading, spacing: 10) {
			label(title)
			content()
			Text(note).font(.caption2).foregroundStyle(Theme.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
	}

	private func label(_ text: String) -> some View {
		Text(text).font(.system(size: 11, weight: .semibold)).tracking(0.8)
			.foregroundStyle(Theme.secondary)
	}

	private func ownedBinding(_ product: FeedProduct) -> Binding<Bool> {
		Binding(get: { settings.ownedProducts.contains(product) },
		        set: { settings.setOwned(product, $0) })
	}
}

#Preview {
	SettingsSheet(settings: .shared, colorScheme: nil)
}
