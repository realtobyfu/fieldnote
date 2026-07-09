# Illustration Sourcing — Real Plates + Attribution

Plan date: July 7, 2026
Supersedes: the "illustration factory / generate illustrations (M3)" line item in
`LocaleAwareCatalogImplementationPlan.md` and `BackendM2Spec.md`.

## Decision

Replace AI-generated botanical illustrations with reproductions of real,
public-domain botanical plates, and attribute the human artists. Original
(AI-generated) house illustrations stay allowed as a fallback but are
**intentionally left uncredited** — a credit exists only when there is a real
person to name.

Why this beats generating illustrations:

- **Aesthetic fit.** Antique engravings *are* the vintage field-journal look the
  app already simulates (aged paper, sepia frames, `ScientificNamePlate`). No
  style-transfer needed — the real thing is on-brand.
- **Legally clean & free.** Pre-1930 works and their faithful scans are public
  domain worldwide. No license fees, no model-provenance questions.
- **Credibility.** "After O.W. Thomé, *Flora von Deutschland*, 1885" signals a
  real reference work, not decoration.

## Current state (grounding)

- **43** bundled illustrations (`Assets.xcassets/Illustrations/…`), enumerated in
  `IllustrationService.availableIllustrations`. **10 are now real public-domain
  plates** (the shipped pilot batch below); the other ~33 remain AI-generated.
- Illustrations resolve by asset name:
  `IllustrationService.illustrationName(for:family:)` →
  `BotanicalIllustrationView`. Attribution therefore keys off the **asset name**,
  not the plant — the credit belongs to the image.
- `IllustrationSources.md` is a two-entry stub and miscredits the dandelion plate
  to "Gemini" (i.e. AI). Under this plan, AI plates get no source row at all;
  that file is superseded by the registry in code + this doc.

## Schema (shipped — prototype)

- `Models/IllustrationCredit.swift` — `creator` (required), optional `title`,
  `publication`, `year`, `sourceURL`, and a `license` enum (`publicDomain`/`cc0`).
  `captionText` renders the antiquarian one-liner defensively from partial data.
- `IllustrationService.illustrationCredits: [String: IllustrationCredit]` — asset
  name → credit. **10 entries** (the shipped pilot batch); absence = original AI
  plate = uncredited. `IllustrationService.credit(for:family:)` resolves it
  through the same name-normalization as illustrations.
- `Components/Images/IllustrationCreditLine.swift` — renders the caption (as a
  tappable `Link` when `sourceURL` is present); renders **nothing** when there is
  no credit, so it's safe to drop in unconditionally.
- Wired into `CatalogPlantDetailView` and `PlantDetailView` beneath the hero
  illustration. In `PlantDetailView` it is suppressed when a user's own custom
  illustration is showing, so the house plate's credit never mis-attributes a
  user image.

To attribute a newly-sourced plate: drop the asset into
`Assets.xcassets/Illustrations/`, add its name to
`IllustrationService.availableIllustrations`, and add one
`illustrationCredits[assetName]` entry. No schema change, no UI change.

## Sourcing workflow (per plant)

1. **Find a plate** for the exact species (or closest congener) in a
   public-domain flora — see sources below.
2. **Confirm PD status:** original publication pre-1930 **and** a faithful
   photographic scan (2-D reproductions of PD works acquire no new copyright,
   per *Bridgeman v. Corel*). Prefer BHL / Wikimedia Commons, which state rights.
3. **Clean** the scan: crop to the plate, flatten to the app's cream paper,
   de-speckle. Keep the plate's own caption/plate-number if legible — it adds to
   the reference feel.
4. **Export** at hero resolution, name it to match the catalog `commonName`
   normalization (lowercase, spaces→`_`, apostrophes stripped — mirror an
   existing asset name), add to the asset catalog + `availableIllustrations`.
5. **Attribute:** add the `illustrationCredits` entry with artist, work, year,
   and the scan's source URL.

## Recommended source works (all public domain)

Redouté is the marquee name but painted French court botany (roses, lilies,
irises) — he can't carry a North American field catalog. Use him where he fits
and lean on floras with real native-species coverage:

| Source | Coverage | Style |
| --- | --- | --- |
| **Britton & Brown**, *Illustrated Flora of the Northern US & Canada* (1913) | Deep North American natives — elms, sycamores, bloodroot, asters | Line engraving |
| **O.W. Thomé**, *Flora von Deutschland* (1885) | Naturalized weeds & wildflowers — dandelion, milkweed kin, clovers | Color litho |
| **Curtis's Botanical Magazine** (1787–) | Showy species, ornamentals | Color plate |
| **Köhler's Medizinal-Pflanzen** (1887) | Medicinal/common herbs | Color litho |
| **P.-J. Redouté**, *Les Roses* / *Les Liliacées* (1817–24) | Roses, lilies, irises — the marquee plates | Stipple engraving |

Primary repositories: Biodiversity Heritage Library (biodiversitylibrary.org),
Wikimedia Commons, USDA/NRCS PLANTS (Britton & Brown scans).

## Pilot batch — SHIPPED (10 real plates, credits live)

Ten high-traffic species. Each bundled asset in `Assets.xcassets/Illustrations/`
has been **replaced** with a real public-domain plate (downloaded from Wikimedia
Commons, cleaned to the app's paper aesthetic, July 2026), and its
`illustrationCredits` entry is now **live** in `IllustrationService`. The credit
line renders on both `CatalogPlantDetailView` and `PlantDetailView`.

| Asset name | Species | Artist | Work | Year | License basis |
| --- | --- | --- | --- | --- | --- |
| `red_oak` | *Quercus rubra* | Charles Edward Faxon | *The Silva of North America*, Vol. VIII | 1895 | PD (pre-1931 US) |
| `red_maple` | *Acer rubrum* | Charles Edward Faxon | *The Silva of North America*, Vol. II | 1895 | PD (pre-1931 US) |
| `dandelion` | *Taraxacum officinale* | Walther Otto Müller | Köhler's *Medizinal-Pflanzen* | 1887 | PD |
| `common_milkweed` | *Asclepias syriaca* | Charles Frederick Millspaugh | *American Medicinal Plants* (pl. 134) | 1887 | PD (pre-1931) |
| `black-eyed_susan` | *Rudbeckia hirta* | Britton & Brown (engraver uncredited) | *Illustrated Flora of the Northern US & Canada* | 1913 | PD (1913 pub.) |
| `purple_coneflower` | *Echinacea purpurea* | Abraham Jacobus Wendel | Witte, *Flora* | 1868 | PD |
| `bloodroot` | *Sanguinaria canadensis* | Jacob Bigelow (author; engraver uncredited) | *American Medical Botany*, pl. VII | 1817 | PD (pre-1931) |
| `trillium` | *Trillium grandiflorum* | Abraham Jacobus Wendel | Witte, *Flora*, pl. 43 | 1868 | PD |
| `cardinal_flower` | *Lobelia cardinalis* | Britton & Brown (engraver uncredited) | *Illustrated Flora of the Northern US & Canada* | 1913 | PD (1913 pub.) |
| `flowering_dogwood` | *Cornus florida* | Britton & Brown (engraver uncredited) | *Illustrated Flora of the Northern US & Canada*, Vol. 2 | 1913 | PD (1913 pub.) |

Source scans (each is the `sourceURL` the credit links to, on Wikimedia Commons):

1. `red_oak` — `File:Silva of North America. Volume VIII, Cupulferæ (quercus), The - DPLA - b9f64d18c757dc555a1796e78beca693 (page 185).jpg`
2. `red_maple` — `File:Silva of North America. Volume II, Cyrillaceae - sapindaceae, The - DPLA - 96d7c6e80c6075e323cf6c3a7ea4cd74 (page 156).jpg`
3. `dandelion` — `File:Taraxacum officinale - Köhler–s Medizinal-Pflanzen-135.jpg`
4. `common_milkweed` — `File:American medicinal plants (Plate 134) (6025430995).jpg`
5. `black-eyed_susan` — `File:Rudbeckia hirta-linedrawing.png`
6. `purple_coneflower` — `File:WitteHeinrichFlora1868-012-Echinacea purpurea.png`
7. `bloodroot` — `File:American medical botany (Pl. VII) BHL2955660.jpg`
8. `trillium` — `File:WitteHeinrichFlora1868-043-Trillium grandiflorum.png`
9. `cardinal_flower` — `File:Lobelia cardinalis L. Cardinalflower.tiff`
10. `flowering_dogwood` — `File:Cornus florida BrittonBrown.png`

Notes on the shipped batch:

- **Walcott swapped out.** Black-eyed susan, trillium, and cardinal flower were
  originally matched to Mary Vaux Walcott's *North American Wild Flowers*, but
  Commons only holds ~350–500px scans of those — too small for a hero. Replaced
  with high-res alternates: susan + cardinal flower from **Britton & Brown** (1913
  line engravings), trillium from **Wendel's Witte *Flora*** (1868 color plate,
  same artist as the coneflower). All PD on a pre-1931-publication basis, which
  also removes the earlier non-renewal / international-distribution caveat.
- **Milkweed** plate is captioned "Asclepias Cornuti" — a historical synonym of
  *A. syriaca*. ID is correct; only the printed caption differs.
- **Uncredited engravers.** Bloodroot (Bigelow) and the three Britton & Brown
  engravings name the work's author; the individual plate engraver is uncredited on
  the scan and we do not invent one.
- **Processing.** Scans were margin-trimmed, paper-normalized to a soft warm cream
  (`250,247,239`) preserving artwork color, and resized to 1600px long side; the
  bloodroot scan's reverse-page show-through was suppressed. Pipeline scripts live
  in the session scratchpad; originals of the replaced AI assets were backed up.

### Registry (live in code)

The 10 credits above are populated in `IllustrationService.illustrationCredits`
with their full `sourceURL`s. To attribute a **future** plate: replace the AI
asset with the real scan first, then add one `illustrationCredits[assetName]`
entry — never credit an asset that is still AI-generated.

## Attribution policy

- Attribute **only** real human artists. AI plates render no credit line.
- Public domain imposes no legal attribution duty; we credit anyway, as courtesy
  and for the antiquarian voice.
- Caption form: `After {creator} · {work}, {year}`, italic caption2, tappable to
  the source scan when a URL is present.
- No fabricated attributions. If provenance is uncertain, leave it uncredited
  rather than guess.

## Sequencing

1. **Schema (done):** model, registry hook, credit-line view, detail-view wiring.
   Ships inert — no visible change while the registry is empty.
2. **Pilot batch (SHIPPED):** 10 high-traffic species — real plates downloaded,
   cleaned, installed as the bundled assets, and credits activated. See the table
   above. Remaining: verify the captions on-device on an iOS 26 build.
3. **Backfill:** work through the remaining ~33 catalog illustrations; extend to
   region-pack species (Milestone 2) as those illustrations are needed.

## Out of scope

- Server-side illustration delivery — assets stay bundled/region-packed per the
  M2 region-pack mechanism; no new endpoint.
- Personalized ranking (Stage-2) — unchanged and unrelated; see
  `BackendM2Spec.md`.
