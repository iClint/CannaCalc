import Foundation

// App metadata read from the bundle's Info.plist. Takes the info dictionary so the version
// formatting is unit-testable without a real bundle.
enum AppInfo {
	static let name = "CannaCalc"

	// "v1.0" — or "v1.0 (3)" when the build number differs from the marketing version.
	static func version(_ info: [String: Any]? = Bundle.main.infoDictionary) -> String {
		let marketing = info?["CFBundleShortVersionString"] as? String ?? "—"
		let build = info?["CFBundleVersion"] as? String
		if let build, build != marketing { return "v\(marketing) (\(build))" }
		return "v\(marketing)"
	}
}
