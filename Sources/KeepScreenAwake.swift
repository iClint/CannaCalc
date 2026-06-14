import SwiftUI
import UIKit

// Holds the screen awake while the app is active so a batch can be mixed without the phone
// sleeping. Released when `enabled` is off or the app leaves the foreground (iOS ignores the
// idle-timer flag in the background anyway, but we clear it explicitly to be a good citizen).
struct KeepScreenAwake: ViewModifier {
	let enabled: Bool
	@Environment(\.scenePhase) private var scenePhase

	func body(content: Content) -> some View {
		content
			.onAppear { apply() }
			.onChange(of: scenePhase) { _, _ in apply() }
			.onChange(of: enabled) { _, _ in apply() }
	}

	private func apply() {
		UIApplication.shared.isIdleTimerDisabled = enabled && scenePhase == .active
	}
}

extension View {
	func keepScreenAwake(_ enabled: Bool) -> some View { modifier(KeepScreenAwake(enabled: enabled)) }
}
