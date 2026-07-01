# Handoff: Finish + QA the Capture/Library/Tab Redesign

You are picking up an in-progress UI redesign of the **Fieldnote** iOS app
(SwiftUI, SwiftData, iOS 18 deployment target; some iOS 26 "Liquid Glass" paths
gated behind `#available`). The redesign introduces a custom Liquid-Glass tab bar
and a new **Journal** home tab, and reworks Capture, Library, and the map. It was
committed mid-flight as a single WIP commit and is **not finished or QA'd**. Your
job is to make it build cleanly from a fresh checkout, finish it, and QA it.

## ⚠️ CRITICAL FIRST TASK — `main` does not build from a clean checkout

The WIP commit added/changed files that **reference other files that were never
committed** (they exist only as untracked files in one working tree). A fresh
`git clone` or CI build will fail to compile. Before anything else, add the
required untracked files to git and verify a clean build.

**Committed code references these UNTRACKED, REQUIRED files:**
- `Fieldnote/Components/Layout/FieldTabBar.swift` — used by `Screens/MainTabView.swift`
- `Fieldnote/Screens/Journal/JournalView.swift` (and `Journal/Demo.swift`) — used by `MainTabView`
- `Fieldnote/Components/Journal/` — `CollectionProgressRow.swift`, `JournalStatsStrip.swift`, `JournalStatusHeader.swift`, `RecentFindCard.swift` (used by the Journal screen)
- `Fieldnote/Models/PlantType.swift` — used by `Screens/Library/LibraryView.swift`
- `Fieldnote/DebugSeed.swift` — used by `FieldnoteApp.swift`
- `Fieldnote/Theme/FieldGlass.swift` — Liquid-Glass theme; used by the tab bar / Journal views

**Likely dev-only / scratch (NOT referenced by committed code — confirm before shipping, probably gate behind DEBUG or delete):**
- `Fieldnote/Screens/DesignLab/DesignLabView.swift`
- `Fieldnote/Screens/AnimationLab/AnimationLabView.swift`

Action: review each required file, `git add` the real ones so `main` compiles
standalone, and decide whether DesignLab/AnimationLab ship (gate behind `#if DEBUG`
or remove). The Xcode project uses **synchronized folder groups**, so dropping
`.swift` files into the tree auto-includes them — do **not** hand-edit
`project.pbxproj` for source files.

## What the WIP commit changed (commit message: "WIP: capture/library/tab redesign and test targets")

| File | Nature |
|---|---|
| `Screens/MainTabView.swift` | New shell with custom `FieldTabBar`; Capture is a center FAB action, not a rendered tab; tabs: journal / explore / capture / map / profile (`enum AppTab` in `Store/AppStore.swift`). |
| `Screens/Capture/CaptureReviewSheet.swift` | Large rewrite — extracted `identificationCard` / `locationCard` / `moreDetailsSection` subviews. |
| `Screens/Capture/CaptureView.swift` | Redesign + capture flow tweaks. |
| `Screens/Library/LibraryView.swift`, `Library/LocationMapView.swift` | Library + map rework (LocationMapView heavily trimmed). |
| `Components/Cards/PlantCard.swift`, `Components/Images/*`, `Components/Ornaments/VintageOrnaments.swift` | Card / illustration / ornament refinements. |
| `FieldnoteApp.swift` | App entry tweaks incl. a `DebugSeed` hook. |
| `Store/AppStore.swift` | `AppTab` enum + minor state. |
| `FieldnoteUnitTests/`, `FieldnoteUITests/` | Test targets were added here (now also used by the locale feature's tests). |

## Interactions with the locale-aware catalog feature (DON'T break these)

A separate, **completed and shipped** feature (locale-aware Explore catalog +
identification reranking) was merged on top of this redesign. Be careful where they
overlap:

- **`CaptureReviewSheet.swift` was hand-merged.** The redesign's structure
  (`identificationCard` / `locationCard` / `moreDetailsSection`) was kept, and an
  `AlternativeCandidatesCard` ("Other possibilities") was slotted in after the
  identification card. Don't drop the alternatives card when finishing the sheet.
- **`Screens/Capture/CaptureViewModel.swift`** drives identification: it calls
  `identifyCandidates` → `LocalRankingService().rerankCandidates(...)`, surfaces a
  reranked top result + close alternatives, and falls back to on-device CoreML
  offline. Preserve that flow.
- **`Store/AppStore.swift`** holds both `AppTab` (redesign) and the locale state
  (`localCatalogItems`, region selection, etc.). Both must keep compiling.
- **Explore tab** has locale sections ("Common in {Region}", "Active in {Month}",
  "More to Look For") + a region picker. Out of scope for the redesign, but don't
  regress it.
- A Pl@ntNet API key currently ships in `Config.plist` — a separate backend task
  will remove it; ignore for the redesign.

## Build / test / run

- Open `Fieldnote.xcodeproj` (no workspace). Single app target `Fieldnote` + test
  targets `FieldnoteUnitTests`, `FieldnoteUITests`.
- Build: `xcodebuild -scheme Fieldnote -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' build`
- Unit tests: `xcodebuild test -scheme Fieldnote -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.0' -only-testing:FieldnoteUnitTests`
- Liquid-Glass paths target an iOS 26 sim (`iPhone 17,OS=26.0`); also smoke-test on
  an **iOS 18** simulator for the opaque/baseline path, since Glass is `#available`-gated.
- Deployment target is **iOS 18**. `SWIFT_VERSION = 5.0` with approachable
  concurrency / `MainActor` default isolation already on.
- SourceKit single-file "Cannot find type X in scope" diagnostics for same-module
  types are **false positives** — trust `xcodebuild`.

## Suggested QA checklist

1. **Clean-checkout build** (the critical task above) — fresh clone compiles with no missing files.
2. **Tab bar**: all tabs switch; Capture FAB opens capture and returns to Journal; safe-area / notch / home-indicator layout; iOS 18 vs 26 (Glass) appearance.
3. **Journal home**: stats strip, status header, collection progress, recent finds render with real + empty data.
4. **Capture flow**: take/pick photo → review sheet → identification card, **alternatives card** when present, location, conditions, notes, save. Manual-entry + offline (airplane mode → CoreML) fallbacks.
5. **Library + map**: list, grouping, `LocationMapView` pins/clustering, navigation into detail.
6. **Explore** (locale feature regression): region picker, "Common in {Region}" / "Active in {Month}" sections, "Why this plant?" lines.
7. **Cross-cutting**: Dynamic Type (XL sizes), VoiceOver labels on the custom tab bar + cards, dark mode, empty states, and the seeded-data debug hooks (`DebugSeed` / `SEED_SAMPLE_DATA` / `SEED_REVIEW` env vars).
8. Decide the fate of `DesignLabView` / `AnimationLabView` (ship gated, or remove).

## Things I (the handing-off agent) do NOT know

- The intended visual spec / design intent of the redesign — it was authored
  outside this session and committed mid-flight. Treat the untracked files as the
  source of truth for intent, but verify they're complete.
- Whether `Journal/Demo.swift`, `DesignLab`, `AnimationLab` are meant to ship.
- Current state of polish — assume nothing is final until QA'd.
