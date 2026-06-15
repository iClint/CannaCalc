import SwiftUI

// Standalone CANNA Coco feed calculator (extracted from TentControl). Pure, offline — no
// device/MQTT. Single screen: pick a growth phase, dial the feed EC, get the mix.
@main
struct CannaCalcApp: App {
	var body: some Scene {
		WindowGroup {
			CalculatorView()
		}
	}
}

// The app's root content (an App scene isn't previewable, so preview its window content).
#Preview {
	CalculatorView()
}
