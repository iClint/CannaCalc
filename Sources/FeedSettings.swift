import Foundation
import Combine

// EC display unit. Coco feeds are dosed in mS/cm; ppm·500 / ppm·700 are the two common
// TDS conversions meters use.
enum ECUnit: String, CaseIterable, Identifiable {
	case mS = "mS/cm"
	case ppm500 = "ppm·500"
	case ppm700 = "ppm·700"
	var id: String { rawValue }
	func convert(_ mS: Double) -> Double {
		switch self {
		case .mS: return mS
		case .ppm500: return mS * 500
		case .ppm700: return mS * 700
		}
	}
	var short: String { self == .mS ? "mS" : "ppm" }
	var decimalPlaces: Int { self == .mS ? 2 : 0 }
}

// App appearance. `.system` follows the device's light/dark setting; the other two force it.
// The SwiftUI `colorScheme` mapping lives in Theme.swift to keep this file UI-framework-free.
enum AppTheme: String, CaseIterable, Identifiable {
	case system
	case light
	case dark
	var id: String { rawValue }
	var label: String {
		switch self {
		case .system: return "System"
		case .light: return "Light"
		case .dark: return "Dark"
		}
	}
}

// Persisted inputs for the feed calculator (UserDefaults-backed). The recipe controls
// (volume / water EC / feed EC) live on the calculator screen; appearance + ecUnit +
// ownedProducts in Settings.
@MainActor
final class FeedSettings: ObservableObject {
	static let shared = FeedSettings()

	// UserDefaults keys, named so the read (init) and write (didSet) of each setting can't drift.
	private enum Key {
		static let volume = "volume"
		static let baseEC = "baseEC"
		static let ecUnit = "ecUnit"
		static let appTheme = "appTheme"
		static let keepScreenAwake = "keepScreenAwake"
		static let ownedProducts = "ownedProducts"
		static let hasSeenDisclaimer = "hasSeenDisclaimer"
	}

	// First-launch defaults (used when nothing is persisted yet).
	private static let defaultVolume = 15.0          // L
	private static let defaultBaseEC = 0.3           // typical soft water (mS/cm)

	// Injectable so tests can use an isolated suite; the app uses `.standard` via `shared`.
	private let ud: UserDefaults

	@Published var volume: Double { didSet { ud.set(volume, forKey: Key.volume) } }
	@Published var baseEC: Double { didSet { ud.set(baseEC, forKey: Key.baseEC) } }   // source-water EC (mS/cm)
	@Published var ecUnit: ECUnit { didSet { ud.set(ecUnit.rawValue, forKey: Key.ecUnit) } }
	@Published var appTheme: AppTheme { didSet { ud.set(appTheme.rawValue, forKey: Key.appTheme) } }
	// Hold the screen awake while the app is open so the phone doesn't sleep mid-mix.
	@Published var keepScreenAwake: Bool { didSet { ud.set(keepScreenAwake, forKey: Key.keepScreenAwake) } }
	// The bottles the grower owns; products outside this set are left out of the recipe.
	@Published var ownedProducts: Set<FeedProduct> {
		didSet { ud.set(ownedProducts.map(\.rawValue), forKey: Key.ownedProducts) }
	}
	// Whether the first-run disclaimer has been acknowledged (so it stops auto-presenting).
	@Published var hasSeenDisclaimer: Bool { didSet { ud.set(hasSeenDisclaimer, forKey: Key.hasSeenDisclaimer) } }

	init(defaults: UserDefaults = .standard) {
		ud = defaults
		volume = ud.object(forKey: Key.volume) as? Double ?? Self.defaultVolume
		baseEC = ud.object(forKey: Key.baseEC) as? Double ?? Self.defaultBaseEC
		ecUnit = ECUnit(rawValue: ud.string(forKey: Key.ecUnit) ?? "") ?? .mS
		appTheme = AppTheme(rawValue: ud.string(forKey: Key.appTheme) ?? "") ?? .system
		keepScreenAwake = ud.object(forKey: Key.keepScreenAwake) as? Bool ?? true
		hasSeenDisclaimer = ud.object(forKey: Key.hasSeenDisclaimer) as? Bool ?? false
		// First launch: assume the grower owns the full CANNA lineup (recipe unchanged).
		if let saved = ud.array(forKey: Key.ownedProducts) as? [String] {
			ownedProducts = Set(saved.compactMap(FeedProduct.init(rawValue:)))
		} else {
			ownedProducts = Set(FeedProduct.allCases)
		}
	}

	// Toggle ownership of an optional product (Coco A & B are core and always dosed).
	func setOwned(_ product: FeedProduct, _ owned: Bool) {
		if owned { ownedProducts.insert(product) } else { ownedProducts.remove(product) }
	}
}
