import SwiftUI

// Cannabis / grow theme: deep forest-charcoal, vivid leaf-green accent.
enum Theme {
	static let bg = LinearGradient(
		colors: [Color(red: 0.03, green: 0.06, blue: 0.04),
		         Color(red: 0.06, green: 0.10, blue: 0.07)],
		startPoint: .top, endPoint: .bottom)

	static let card = Color(red: 0.08, green: 0.12, blue: 0.09)
	static let cardStroke = Color(red: 0.45, green: 0.85, blue: 0.40).opacity(0.12)
	static let accent = Color(red: 0.40, green: 0.84, blue: 0.34)   // leaf green
	static let primary = Color.white
	static let secondary = Color(red: 0.60, green: 0.70, blue: 0.60).opacity(0.85)  // sage
	static let track = Color.white.opacity(0.10)
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
			.shadow(color: .black.opacity(0.40), radius: 12, x: 0, y: 8)
	}
}

extension View {
	func glassCard() -> some View { modifier(GlassCard()) }
}
