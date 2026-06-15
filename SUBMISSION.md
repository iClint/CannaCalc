# App Store submission checklist — CannaCalc

Reference for submitting CannaCalc to App Store Connect (ASC). Items marked **ASC**
are set in App Store Connect, not in code.

## Identity
- **Display name:** CannaCalc
- **Bundle ID:** `com.clintkingston.CannaCalc` (permanent after first submission)
- **Version / build:** 1.0 (1) — bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` in `project.yml` for later releases
- **Privacy Policy URL:** https://iclint.github.io/PrivayPolicies/cannacalc/

## Age rating — target 17+ (18+ under Apple's newer bands) — **ASC**
CannaCalc gives cannabis cultivation guidance (growth phases, harvest cues), so it
must carry the adult rating. In the ASC **Age Rating** questionnaire:

- **Alcohol, Tobacco, or Drug Use or References → set to "Frequent/Intense"**
  (this single answer drives the 17+/18+ rating).
- All other categories (violence, sexual content, gambling, horror, etc.) → **None**.
- Unrestricted web access → **No**. Gambling/contests → **No**.

Do **not** under-declare — an app that facilitates cannabis growing with a low rating
is a likely rejection.

## Export compliance — already handled
`ITSAppUsesNonExemptEncryption = false` is set in `Info.plist` (the app is fully
offline and uses no encryption), so ASC will skip the per-submission prompt.

## Privacy "nutrition label" — **ASC**
- **Data Not Collected** — the app is fully offline, stores only preferences on-device,
  has no network, analytics, ads, or tracking. This matches `PrivacyInfo.xcprivacy`.

## Category — **ASC**
- Suggested primary: **Lifestyle** (or **Utilities**). Secondary optional.

## App Review notes — **ASC** (paste into "Notes")
> CannaCalc is an independent horticultural nutrient calculator. It computes feed
> recipes from the publicly published CANNA Coco grow schedule and works fully
> offline (no accounts, network, or data collection). It is not affiliated with,
> endorsed by, or sponsored by CANNA; product names are used descriptively to
> identify the products it doses ("Canna" is also the common abbreviation for the
> plant). A disclaimer to this effect is shown on first launch and in Settings.

## Availability — **ASC**
Consider restricting territory availability to regions where cannabis cultivation is
lawful; Apple may request this for cultivation-related apps.

## Screenshots / metadata — **ASC**
- Don't imply CANNA endorsement in screenshots, name, subtitle, or description.
- Describe it as a horticultural/nutrient feed calculator.

## Pre-flight (local)
- [ ] `xcodegen generate`
- [ ] Archive a Release build for a generic iOS device and validate in Organizer
- [ ] Confirm app icon, launch screen, first-run disclaimer, and Privacy Policy link
- [ ] All tests green
