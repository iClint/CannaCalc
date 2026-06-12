import SwiftUI

// Standalone CANNA Coco feed calculator (extracted from TentControl). Pure, offline — no
// device/MQTT. Single screen: pick a growth phase, dial the feed EC, get the mix.
@main
struct CocoFeedApp: App {
	var body: some Scene {
		WindowGroup {
			CalculatorView()
		}
	}
}
