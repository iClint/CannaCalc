import SwiftUI

struct CalculatorView: View {
	@ObservedObject private var settings = FeedSettings.shared
	@State private var phase: GrowthPhase = .vegetativeII
	// Target feed EC (total mS/cm) the recipe makes; the A&B dose is back-solved to hit it.
	@State private var targetEC: Double = CannaCoco.defaultEC(.vegetativeII)
	@State private var showBatchDetails = false
	@State private var showPhasePicker = false
	@State private var showSettings = false

	private var recipe: Recipe {
		CannaCoco.recipe(phase: phase, volumeL: settings.volume, waterEC: settings.baseEC,
		                 basePH: settings.basePH, targetEC: targetEC,
		                 phHeadroom: settings.phUpHeadroom ? 0.1 : 0)
	}
	// A&B the recipe actually doses (reflects the pH-up headroom when enabled).
	private var abEach: Double { recipe.items.first { $0.name == "CANNA Coco A" }?.mlPerL ?? 0 }
	private var calMag: Double { CannaCoco.calMag(waterEC: settings.baseEC) }

	// EC formatting in the user's chosen unit (mS or ppm).
	private func ecNum(_ mS: Double) -> String {
		String(format: "%.\(settings.ecUnit.decimalPlaces)f", settings.ecUnit.convert(mS))
	}
	private func ecVal(_ mS: Double) -> String { "\(ecNum(mS)) \(settings.ecUnit.short)" }

	// Tint by where the chosen EC sits vs CANNA's default: cyan (gentler) · green (CANNA) · orange (stronger).
	private func ecTint(_ ec: Double) -> Color {
		let def = CannaCoco.defaultEC(phase)
		if abs(ec - def) < 0.05 { return Theme.accent }
		return ec < def ? .cyan : .orange
	}

	var body: some View {
		ZStack {
			Theme.bg.ignoresSafeArea()
			ScrollView {
				VStack(spacing: 14) {
					header
					phaseSummary
					if phase.isHarvest {
						harvestCard
					} else {
						inputsCard
						recipeCard
					}
				}
				.padding(.horizontal, 16).padding(.top, 6).padding(.bottom, 24)
			}
		}
		.preferredColorScheme(.dark)
		.tint(Theme.accent)
		// Each phase opens at CANNA's recommended feed EC.
		.onChange(of: phase) { _, newPhase in targetEC = CannaCoco.defaultEC(newPhase) }
		.sheet(isPresented: $showPhasePicker) { phasePickerSheet }
		.sheet(isPresented: $showSettings) { settingsSheet }
	}

	// MARK: - Header

	private var header: some View {
		HStack(spacing: 8) {
			Image(systemName: "testtube.2")
				.font(.title3).foregroundStyle(Theme.accent)
				.shadow(color: Theme.accent.opacity(0.6), radius: 6)
			VStack(alignment: .leading, spacing: 1) {
				Text("Feed mix").font(.title2.weight(.bold)).foregroundStyle(Theme.primary)
				Text("CANNA Coco · AU schedule").font(.caption2.weight(.medium)).foregroundStyle(Theme.secondary)
			}
			Spacer()
			Button { showSettings = true } label: {
				Image(systemName: "gearshape.fill")
					.font(.title3).foregroundStyle(Theme.secondary)
			}
		}
	}

	// MARK: - Phase (compact summary → tap opens the card picker)

	private var phaseSummary: some View {
		Button { showPhasePicker = true } label: {
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 12) {
					Image(systemName: "leaf.fill")
						.font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.accent)
						.frame(width: 30, height: 30)
						.background(Theme.accent.opacity(0.16), in: Circle())
					VStack(alignment: .leading, spacing: 1) {
						Text("GROWTH PHASE")
							.font(.system(size: 10, weight: .semibold)).tracking(0.5)
							.foregroundStyle(Theme.secondary)
						Text(phase.rawValue).font(.headline.weight(.bold)).foregroundStyle(Theme.primary)
					}
					Spacer()
					Text(phase.light)
						.font(.caption2.weight(.semibold)).foregroundStyle(Theme.accent)
						.padding(.horizontal, 8).padding(.vertical, 3)
						.background(Theme.accent.opacity(0.14), in: Capsule())
					Image(systemName: "chevron.up.chevron.down")
						.font(.caption.weight(.bold)).foregroundStyle(Theme.accent)
				}
				Text(phase.trigger)
					.font(.caption2).foregroundStyle(Theme.secondary)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(14)
			.glassCard()
		}
		.buttonStyle(.plain)
	}

	private var phasePickerSheet: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 8) {
					ForEach(GrowthPhase.allCases) { p in phaseCard(p) }
				}
				.padding(16)
			}
			.background(Theme.bg.ignoresSafeArea())
			.navigationTitle("Growth phase")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { showPhasePicker = false }.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(.dark)
	}

	private func phaseCard(_ p: GrowthPhase) -> some View {
		let selected = p == phase
		return Button {
			phase = p
			showPhasePicker = false
		} label: {
			VStack(alignment: .leading, spacing: 4) {
				HStack(spacing: 8) {
					Text(p.rawValue).font(.subheadline.weight(.bold))
						.foregroundStyle(selected ? Theme.accent : Theme.primary)
					Spacer()
					Text(p.light)
						.font(.caption2.weight(.semibold))
						.foregroundStyle(selected ? Theme.accent : Theme.secondary)
						.padding(.horizontal, 8).padding(.vertical, 3)
						.background((selected ? Theme.accent : Theme.secondary).opacity(0.14), in: Capsule())
				}
				Text(p.trigger)
					.font(.caption2).foregroundStyle(Theme.secondary)
					.fixedSize(horizontal: false, vertical: true)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
			.padding(12)
			.background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
			.overlay(
				RoundedRectangle(cornerRadius: 14)
					.strokeBorder(selected ? Theme.accent : Theme.cardStroke,
					              lineWidth: selected ? 1.5 : 1)
			)
		}
		.buttonStyle(.plain)
	}

	// MARK: - Settings (EC unit + pH-up allowance)

	private var settingsSheet: some View {
		NavigationStack {
			ZStack {
				Theme.bg.ignoresSafeArea()
				ScrollView {
					VStack(alignment: .leading, spacing: 10) {
						Text("EC UNIT")
							.font(.system(size: 11, weight: .semibold)).tracking(0.8)
							.foregroundStyle(Theme.secondary)
						Picker("", selection: $settings.ecUnit) {
							ForEach(ECUnit.allCases) { Text($0.rawValue).tag($0) }
						}
						.pickerStyle(.segmented)
						Text("How EC is shown throughout the recipe.")
							.font(.caption2).foregroundStyle(Theme.secondary)
					}
					.padding(16).glassCard()
					.padding(16)
				}
			}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { showSettings = false }.tint(Theme.accent)
				}
			}
		}
		.preferredColorScheme(.dark)
	}

	// MARK: - Inputs

	private var inputsCard: some View {
		VStack(spacing: 16) {
			batchVolumeRow
			if showBatchDetails {
				waterECRow
				sliderRow("Base water pH", value: $settings.basePH, range: 4.5...8.5, step: 0.1,
				          display: String(format: "%.1f", settings.basePH), tint: .orange)
				if phase.feedsNutrients {
					feedECControl
					phUpToggle
				}
			}
		}
		.padding(16)
		.glassCard()
	}

	// Batch volume stays visible; the chevron reveals the set-once water EC + pH controls.
	private var batchVolumeRow: some View {
		VStack(spacing: 6) {
			HStack(spacing: 10) {
				Text("Batch volume").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(String(format: "%.0f L", settings.volume))
					.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(Theme.accent)
				Button {
					withAnimation(.easeInOut(duration: 0.2)) { showBatchDetails.toggle() }
				} label: {
					Image(systemName: "chevron.down")
						.font(.caption.weight(.bold)).foregroundStyle(Theme.secondary)
						.rotationEffect(.degrees(showBatchDetails ? 180 : 0))
				}
			}
			Slider(value: $settings.volume, in: 1...50, step: 1).tint(Theme.accent)
		}
	}

	// Source-water EC drives the CalMag dose (full 1.1 ml/L at 0 EC → 0 at CANNA's ideal 0.4).
	private var waterECRow: some View {
		VStack(spacing: 6) {
			HStack {
				Text("Source water EC").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(calMag > 0.001 ? "CalMag \(String(format: "%.1f", calMag)) ml/L" : "no CalMag")
					.font(.caption.weight(.medium)).foregroundStyle(Theme.accent)
				Text(String(format: "%.2f mS", settings.baseEC))
					.font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(.cyan)
			}
			Slider(value: $settings.baseEC, in: 0...0.4, step: 0.05).tint(.cyan)
		}
	}

	// Target-EC control: drag the feed EC directly (0.1 steps); the A&B is back-solved to hit
	// it, clamped to the phase's safe band. Range = that phase's gentle…strong EC.
	private var feedECControl: some View {
		let range = CannaCoco.ecRange(phase)
		let def = CannaCoco.defaultEC(phase)
		return VStack(spacing: 8) {
			HStack(alignment: .firstTextBaseline) {
				Text("Feed EC").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(ecVal(recipe.targetEC))
					.font(.subheadline.weight(.bold).monospacedDigit())
					.foregroundStyle(ecTint(targetEC))
			}
			Slider(value: $targetEC, in: range, step: 0.1).tint(ecTint(targetEC))
			HStack {
				Text(ecVal(range.lowerBound)).font(.caption2).foregroundStyle(.cyan)
				Spacer()
				Text(abs(targetEC - def) < 0.05 ? "CANNA" : "CANNA \(ecVal(def))")
					.font(.caption2.weight(.semibold)).foregroundStyle(Theme.secondary)
				Spacer()
				Text(ecVal(range.upperBound)).font(.caption2).foregroundStyle(.orange)
			}
			Text("Coco A&B \(String(format: "%.1f", abEach)) ml/L each — back-solved to hit this EC. Lower for a stressed plant; raise only if runoff EC is stripping and it's thriving.")
				.font(.caption2).foregroundStyle(Theme.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
		}
	}

	// Reserve 0.1 EC for the bump pH-Up adds, so the mix is dosed 0.1 lower and lands on target.
	private var phUpToggle: some View {
		Toggle(isOn: $settings.phUpHeadroom) {
			VStack(alignment: .leading, spacing: 2) {
				Text("Allow 0.1 EC for pH Up").font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Text("Doses A&B 0.1 mS lower so the feed lands on target after you pH-Up.")
					.font(.caption2).foregroundStyle(Theme.secondary)
			}
		}
		.tint(Theme.accent)
	}

	private func sliderRow(_ title: String, value: Binding<Double>,
	                       range: ClosedRange<Double>, step: Double,
	                       display: String, tint: Color) -> some View {
		VStack(spacing: 6) {
			HStack {
				Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
				Spacer()
				Text(display).font(.subheadline.weight(.bold).monospacedDigit()).foregroundStyle(tint)
			}
			Slider(value: value, in: range, step: step).tint(tint)
		}
	}

	// MARK: - Recipe

	private var recipeCard: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("RECIPE")
				.font(.system(size: 11, weight: .semibold)).tracking(0.8)
				.foregroundStyle(Theme.secondary)

			VStack(spacing: 0) {
				ForEach(Array(recipe.items.enumerated()), id: \.element.id) { idx, item in
					itemRow(item)
					if idx < recipe.items.count - 1 { Divider().overlay(Theme.cardStroke) }
				}
			}

			Divider().overlay(Theme.cardStroke)
			summaryRow("Aim EC", ecVal(recipe.targetEC), note: "total", ok: true)
			summaryRow("pH", String(format: "%.1f", settings.basePH),
			           note: recipe.phNote, ok: recipe.phTarget.contains(settings.basePH))

			VStack(alignment: .leading, spacing: 4) {
				Text("Mix order: CalMag first → confirm water reads ~0.4 mS/cm → A → B → Rhizotonic → Cannazym → CannaBoost → PK → pH last.")
				if settings.phUpHeadroom && phase.feedsNutrients {
					Text("Mixed, it reads ~\(ecVal(recipe.mixEC)); pH-Up adds ~0.1 to reach \(ecVal(recipe.targetEC)).")
						.foregroundStyle(Theme.accent.opacity(0.9))
				}
				if settings.baseEC < 0.4 {
					Text("Add CalMag to the raw water and verify it reads ~0.4 mS/cm before adding A&B.")
						.foregroundStyle(Theme.accent.opacity(0.9))
				}
			}
			.font(.caption2).foregroundStyle(Theme.secondary).padding(.top, 2)
		}
		.padding(16)
		.glassCard()
	}

	private func itemRow(_ item: RecipeItem) -> some View {
		let active = item.mlPerL > 0.001
		return HStack {
			Text(item.name).font(.subheadline.weight(.medium))
				.foregroundStyle(active ? Theme.primary : Theme.secondary.opacity(0.45))
			Spacer()
			if active {
				Text(String(format: "%.1f ml/L", item.mlPerL))
					.font(.caption.monospacedDigit()).foregroundStyle(Theme.secondary)
				Text("\(Int(item.ml)) ml")
					.font(.subheadline.weight(.bold).monospacedDigit())
					.foregroundStyle(Theme.accent)
					.frame(width: 78, alignment: .trailing)
			} else {
				Text("—").font(.subheadline.weight(.medium))
					.foregroundStyle(Theme.secondary.opacity(0.4))
					.frame(width: 78, alignment: .trailing)
			}
		}
		.padding(.vertical, 9)
	}

	private func summaryRow(_ title: String, _ value: String, note: String, ok: Bool) -> some View {
		HStack {
			Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Theme.primary)
			Spacer()
			Text(note).font(.caption).foregroundStyle(ok ? Theme.accent : .orange)
			Text(value).font(.subheadline.weight(.bold).monospacedDigit())
				.foregroundStyle(Theme.primary).frame(width: 78, alignment: .trailing)
		}
		.padding(.vertical, 4)
	}

	// MARK: - Harvest

	private var harvestCard: some View {
		VStack(spacing: 12) {
			Image(systemName: "scissors")
				.font(.system(size: 34)).foregroundStyle(Theme.accent)
				.shadow(color: Theme.accent.opacity(0.5), radius: 8)
			Text("Time to chop").font(.headline.weight(.bold)).foregroundStyle(Theme.primary)
			Text(GrowthPhase.harvest.trigger)
				.font(.subheadline).foregroundStyle(Theme.secondary)
				.multilineTextAlignment(.center)
			Text("No feed — harvest after any final flush.")
				.font(.caption2).foregroundStyle(Theme.secondary)
		}
		.frame(maxWidth: .infinity)
		.padding(20)
		.glassCard()
	}
}
