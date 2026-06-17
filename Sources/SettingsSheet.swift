import SwiftUI

// Settings: appearance, keep-awake, EC unit, and which products the grower owns. Presented as a
// sheet; `colorScheme` carries the app's forced appearance into the sheet hierarchy.
struct SettingsSheet: View {
	@ObservedObject var settings: FeedSettings
	let colorScheme: ColorScheme?
	let phase: GrowthPhase   // current phase, so product info can show "right now" usage
	@Environment(\.dismiss) private var dismiss
	@State private var showDisclaimer = false
	@State private var infoProduct: FeedProduct?

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

	// Every product, with an (i) for what it is and when it's used. Base Coco A & B are always in
	// the mix; the optional bottles toggle on/off by what the grower owns.
	private var productsCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			label("PRODUCTS YOU HAVE")
			Text("Coco A & B are the base and always in the mix. Turn off any other bottle you don't own and it's left out of the recipe. Tap ⓘ for what each is and when it's used.")
				.font(.caption2).foregroundStyle(Theme.secondary)
			VStack(spacing: 0) {
				ForEach(Array(FeedProduct.allCases.enumerated()), id: \.element.id) { idx, product in
					productRow(product)
					if idx < FeedProduct.allCases.count - 1 { Divider().overlay(Theme.cardStroke) }
				}
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding(16).glassCard()
		.sheet(item: $infoProduct) { product in
			ProductInfoSheet(product: product, phase: phase, colorScheme: colorScheme)
		}
	}

	@ViewBuilder
	private func productRow(_ product: FeedProduct) -> some View {
		HStack(spacing: 10) {
			if product.isCore {
				Text(product.rawValue)
					.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Text("BASE").font(.caption2.weight(.bold)).foregroundStyle(Theme.secondary)
					.padding(.horizontal, 8).padding(.vertical, 3)
					.background(Theme.secondary.opacity(0.14), in: Capsule())
				Spacer()
			} else {
				Toggle(isOn: ownedBinding(product)) {
					Text(product.rawValue)
						.font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				}
				.tint(Theme.accent)
			}
			Button { infoProduct = product } label: {
				Image(systemName: "info.circle").font(.body).foregroundStyle(Theme.accent)
					.frame(width: 30, height: 30).contentShape(Rectangle())
			}
			.buttonStyle(.plain)
		}
		.padding(.vertical, 5)
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
	SettingsSheet(settings: .shared, colorScheme: nil, phase: .vegetativeII)
}
