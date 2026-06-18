import SwiftUI
import UIKit

// Bridges the persisted AppTheme to SwiftUI's optional ColorScheme: `.system` → nil (let the
// device decide), otherwise force the chosen scheme.
extension AppTheme {
	var colorScheme: ColorScheme? {
		switch self {
		case .system: return nil
		case .light: return .light
		case .dark: return .dark
		}
	}
}

// Cannabis / grow theme. Every colour is an adaptive pair, so views follow the system (or the
// user's forced) light/dark appearance automatically — light is a clean leaf-on-white look,
// dark keeps the original deep forest-charcoal with a vivid leaf-green accent.
enum Theme {
	private static func adaptive(light: UIColor, dark: UIColor) -> Color {
		Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
	}
	private static func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> UIColor {
		UIColor(red: r, green: g, blue: b, alpha: a)
	}

	// Background gradient (built from adaptive stops so the whole gradient flips with the scheme).
	static let bgTop = adaptive(light: rgb(0.94, 0.97, 0.93), dark: rgb(0.03, 0.06, 0.04))
	static let bgBottom = adaptive(light: rgb(0.87, 0.93, 0.86), dark: rgb(0.06, 0.10, 0.07))
	static let bg = LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)

	static let card = adaptive(light: rgb(1, 1, 1), dark: rgb(0.08, 0.12, 0.09))
	static let cardStroke = adaptive(light: rgb(0.20, 0.55, 0.20, 0.22), dark: rgb(0.45, 0.85, 0.40, 0.12))
	static let accent = adaptive(light: rgb(0.18, 0.58, 0.22), dark: rgb(0.40, 0.84, 0.34))   // leaf green
	static let primary = adaptive(light: rgb(0.07, 0.12, 0.08), dark: rgb(1, 1, 1))
	static let secondary = adaptive(light: rgb(0.32, 0.42, 0.34, 0.95), dark: rgb(0.60, 0.70, 0.60, 0.85))  // sage
	static let track = adaptive(light: rgb(0, 0, 0, 0.08), dark: rgb(1, 1, 1, 0.10))
	// Drop shadow: heavy on dark, barely-there on light so cards don't look muddy.
	static let cardShadow = adaptive(light: rgb(0.20, 0.30, 0.20, 0.12), dark: rgb(0, 0, 0, 0.40))
}

// Glassy elevated card: dark green fill, hairline border, soft drop shadow.
struct GlassCard: ViewModifier {
	func body(content: Content) -> some View {
		content
			.background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 22, style: .continuous)
					.strokeBorder(Theme.cardStroke, lineWidth: 1)
			)
			.shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 8)
	}
}

extension View {
	func glassCard() -> some View { modifier(GlassCard()) }
}

// Rough stage-length label with a clock (e.g. 🕐 2–3 wk). Hidden for "—" (harvest). Kept lighter
// than LightBadge (no filled pill) so it reads as secondary planning info.
struct DurationLabel: View {
	let text: String

	var body: some View {
		if text != "—" {
			HStack(spacing: 3) {
				Image(systemName: "clock").font(.system(size: 9, weight: .bold))
				Text(text).font(.caption2.weight(.medium))
			}
			.foregroundStyle(Theme.secondary)
		}
	}
}

// Light-schedule pill with a little sun (e.g. ☀︎ 18 h, ☀︎ 12/12). No sun for "—" (harvest).
struct LightBadge: View {
	let light: String
	var tint: Color = Theme.accent

	var body: some View {
		HStack(spacing: 3) {
			if light != "—" {
				Image(systemName: "sun.max.fill").font(.system(size: 9, weight: .bold))
			}
			Text(light).font(.caption2.weight(.semibold))
		}
		.foregroundStyle(tint)
		.padding(.horizontal, 8).padding(.vertical, 3)
		.background(tint.opacity(0.14), in: Capsule())
	}
}

// A glassCard over the adaptive background, plus accent / primary / secondary swatches, so the
// theme can be eyeballed in both appearances from the Xcode canvas.
private struct ThemePreview: View {
	var body: some View {
		ZStack {
			Theme.bg.ignoresSafeArea()
			VStack(alignment: .leading, spacing: 14) {
				Text("Feed mix").font(.title2.weight(.bold)).foregroundStyle(Theme.primary)
				Text("CANNA Coco · AU schedule").font(.caption).foregroundStyle(Theme.secondary)
				HStack(spacing: 10) {
					swatch("accent", Theme.accent)
					swatch("card", Theme.card)
					swatch("stroke", Theme.cardStroke)
				}
			}
			.padding(16)
			.frame(maxWidth: .infinity, alignment: .leading)
			.glassCard()
			.padding(24)
		}
	}

	private func swatch(_ label: String, _ color: Color) -> some View {
		VStack(spacing: 4) {
			RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 44, height: 44)
				.overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Theme.cardStroke))
			Text(label).font(.caption2).foregroundStyle(Theme.secondary)
		}
	}
}

#Preview("Theme – Light") {
	ThemePreview().environment(\.colorScheme, .light)
}

#Preview("Theme – Dark") {
	ThemePreview().environment(\.colorScheme, .dark)
}
