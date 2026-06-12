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

// Persisted inputs for the feed calculator (UserDefaults-backed). The recipe controls
// (volume / water EC / pH) live on the calculator screen; ecUnit + phUpHeadroom in Settings.
@MainActor
final class FeedSettings: ObservableObject {
	static let shared = FeedSettings()
	private let ud = UserDefaults.standard

	@Published var volume: Double { didSet { ud.set(volume, forKey: "volume") } }
	@Published var baseEC: Double { didSet { ud.set(baseEC, forKey: "baseEC") } }      // source-water EC (mS/cm)
	@Published var basePH: Double { didSet { ud.set(basePH, forKey: "basePH") } }
	@Published var ecUnit: ECUnit { didSet { ud.set(ecUnit.rawValue, forKey: "ecUnit") } }
	@Published var phUpHeadroom: Bool { didSet { ud.set(phUpHeadroom, forKey: "phUpHeadroom") } }

	private init() {
		volume = ud.object(forKey: "volume") as? Double ?? 15        // L
		baseEC = ud.object(forKey: "baseEC") as? Double ?? 0.3       // typical soft water
		basePH = ud.object(forKey: "basePH") as? Double ?? 7.0
		ecUnit = ECUnit(rawValue: ud.string(forKey: "ecUnit") ?? "") ?? .mS
		phUpHeadroom = ud.object(forKey: "phUpHeadroom") as? Bool ?? false
	}
}
