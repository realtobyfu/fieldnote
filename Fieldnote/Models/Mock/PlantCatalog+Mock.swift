//
//  PlantCatalog+Mock.swift
//  Fieldnote
//
//  50 common plants for the discovery catalog
//

import Foundation

extension CatalogPlant {
    // MARK: - Full Catalog (50 plants)

    static let catalog: [CatalogPlant] = [
        // TREES (12)
        CatalogPlant(
            commonName: "Red Oak",
            scientificName: "Quercus rubra",
            family: "Fagaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Fast-growing oak with lobed leaves and red-tinted fall color; a major hardwood for timber and wildlife food.",
            traits: ["Pointed leaf lobes", "Acorns", "Fall color"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 49005,
            monthlyAffinity: [0.19, 0.15, 0.22, 0.48, 0.74, 0.71, 0.66, 0.68, 0.8, 1.0, 0.58, 0.19]
        ),
        CatalogPlant(
            commonName: "Sugar Maple",
            scientificName: "Acer saccharum",
            family: "Sapindaceae",
            habitat: "forests",
            nativeRange: "Native to NE North America",
            summary: "Iconic maple tapped for syrup; brilliant orange-red fall color and dense wood prized for floors and furniture.",
            traits: ["5-lobed leaves", "Brilliant fall color", "Maple syrup"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 52543,
            monthlyAffinity: [0.09, 0.1, 0.15, 0.36, 0.75, 0.64, 0.57, 0.59, 0.79, 1.0, 0.26, 0.09]
        ),
        CatalogPlant(
            commonName: "White Pine",
            scientificName: "Pinus strobus",
            family: "Pinaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Tall, soft-needled pine with 5-needle bundles; valued for lumber and shelter, and a classic landscape tree.",
            traits: ["5 needles per bundle", "Long cones", "Soft wood"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 52391,
            monthlyAffinity: [0.33, 0.32, 0.54, 1.0, 0.77, 0.6, 0.54, 0.57, 0.71, 0.65, 0.39, 0.31]
        ),
        CatalogPlant(
            commonName: "Paper Birch",
            scientificName: "Betula papyrifera",
            family: "Betulaceae",
            habitat: "forests",
            nativeRange: "Native to northern North America",
            summary: "White peeling bark and airy canopy; a pioneer tree of cool forests and historically used for canoes and baskets.",
            traits: ["White peeling bark", "Triangular leaves", "Catkins"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 49883,
            monthlyAffinity: [0.44, 0.45, 0.6, 1.0, 0.86, 0.73, 0.77, 0.77, 0.8, 0.75, 0.45, 0.35]
        ),
        CatalogPlant(
            commonName: "Weeping Willow",
            scientificName: "Salix babylonica",
            family: "Salicaceae",
            habitat: "wetlands",
            nativeRange: "Introduced from East Asia",
            summary: "Graceful, drooping branches over water; widely planted ornamental but brittle wood and short-lived in storms.",
            traits: ["Drooping branches", "Narrow leaves", "Near water"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 58316,
            monthlyAffinity: [0.24, 0.26, 0.46, 1.0, 0.75, 0.35, 0.33, 0.31, 0.47, 0.52, 0.36, 0.24]
        ),
        CatalogPlant(
            commonName: "American Sycamore",
            scientificName: "Platanus occidentalis",
            family: "Platanaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Huge riverbank tree with mottled, peeling bark; tolerant of floods and pollution, often seen in cities and parks.",
            traits: ["Mottled bark", "Large maple-like leaves", "Ball fruits"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 49662,
            monthlyAffinity: [0.29, 0.33, 0.51, 1.0, 0.69, 0.58, 0.48, 0.54, 0.71, 0.85, 0.59, 0.34]
        ),
        CatalogPlant(
            commonName: "Eastern Hemlock",
            scientificName: "Tsuga canadensis",
            family: "Pinaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Shade-loving evergreen with flat needles and small cones; forms cool, dark ravines but threatened by adelgid.",
            traits: ["Small flat needles", "Tiny cones", "Graceful form"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 48734,
            monthlyAffinity: [0.37, 0.38, 0.57, 1.0, 0.81, 0.68, 0.6, 0.58, 0.72, 0.64, 0.43, 0.36]
        ),
        CatalogPlant(
            commonName: "Flowering Dogwood",
            scientificName: "Cornus florida",
            family: "Cornaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Spring \"flowers\" are showy bracts; red berries feed birds, and it's a beloved understory tree in woodlands.",
            traits: ["White bracts", "Red berries", "Layered branches"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 54777,
            monthlyAffinity: [0.02, 0.02, 0.24, 1.0, 0.4, 0.07, 0.05, 0.07, 0.2, 0.19, 0.06, 0.02]
        ),
        CatalogPlant(
            commonName: "American Elm",
            scientificName: "Ulmus americana",
            family: "Ulmaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Classic vase-shaped street tree once ubiquitous; many lost to Dutch elm disease, but resistant cultivars exist.",
            traits: ["Vase shape", "Asymmetric leaves", "Samaras"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 53547,
            monthlyAffinity: [0.13, 0.21, 0.42, 1.0, 0.9, 0.78, 0.61, 0.6, 0.79, 0.59, 0.24, 0.14]
        ),
        CatalogPlant(
            commonName: "Black Cherry",
            scientificName: "Prunus serotina",
            family: "Rosaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Fragrant spring blooms and dark cherries for wildlife; valuable reddish wood used in fine furniture and cabinets.",
            traits: ["Dark bark", "White flower clusters", "Small cherries"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 54834,
            monthlyAffinity: [0.09, 0.11, 0.25, 0.86, 1.0, 0.54, 0.42, 0.4, 0.34, 0.29, 0.16, 0.09]
        ),
        CatalogPlant(
            commonName: "Red Maple",
            scientificName: "Acer rubrum",
            family: "Sapindaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Highly adaptable maple with early red flowers and vivid fall color; common in wetlands, yards, and forests.",
            traits: ["Red twigs", "V-shaped sinuses", "Brilliant red fall"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 48098,
            monthlyAffinity: [0.12, 0.2, 0.45, 1.0, 0.85, 0.69, 0.56, 0.52, 0.8, 0.93, 0.31, 0.1]
        ),
        CatalogPlant(
            commonName: "Eastern Redbud",
            scientificName: "Cercis canadensis",
            family: "Fabaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Pink pea-like blooms burst on bare branches in spring; heart-shaped leaves and great as a small yard tree.",
            traits: ["Pink flowers on branches", "Heart-shaped leaves", "Spring bloomer"],
            defaultPlaceholder: "tree.fill",
            inaturalistTaxonID: 48502,
            monthlyAffinity: [0.02, 0.08, 0.55, 1.0, 0.43, 0.26, 0.18, 0.18, 0.28, 0.23, 0.09, 0.02]
        ),

        // WILDFLOWERS (15)
        CatalogPlant(
            commonName: "Black-eyed Susan",
            scientificName: "Rudbeckia hirta",
            family: "Asteraceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Golden daisy flowers with dark centers; tough prairie/wildflower staple that feeds pollinators and birds.",
            traits: ["Yellow petals", "Dark center", "Daisy-like"],
            defaultPlaceholder: "sun.max.fill",
            inaturalistTaxonID: 62741,
            monthlyAffinity: [0.01, 0.01, 0.03, 0.17, 0.31, 0.77, 1.0, 0.43, 0.25, 0.14, 0.04, 0.02]
        ),
        CatalogPlant(
            commonName: "Purple Coneflower",
            scientificName: "Echinacea purpurea",
            family: "Asteraceae",
            habitat: "meadows",
            nativeRange: "Native to central/eastern US",
            summary: "Purple rays around a spiky cone; popular perennial for pollinators and widely used in herbal products.",
            traits: ["Purple petals", "Spiny center", "Medicinal"],
            defaultPlaceholder: "sun.max.fill",
            inaturalistTaxonID: 48627,
            monthlyAffinity: [0.01, 0.0, 0.01, 0.03, 0.06, 0.33, 1.0, 0.6, 0.36, 0.12, 0.02, 0.0]
        ),
        CatalogPlant(
            commonName: "Common Dandelion",
            scientificName: "Taraxacum officinale",
            family: "Asteraceae",
            habitat: "urban",
            nativeRange: "Introduced from Eurasia",
            summary: "Sunny yellow flowers become windblown seed puffs; edible greens and roots, yet a notorious lawn colonizer.",
            traits: ["Yellow flowers", "Puffball seeds", "Rosette leaves"],
            defaultPlaceholder: "sun.max.fill",
            inaturalistTaxonID: 47602,
            monthlyAffinity: [0.06, 0.08, 0.2, 1.0, 0.69, 0.25, 0.14, 0.13, 0.16, 0.16, 0.1, 0.06]
        ),
        CatalogPlant(
            commonName: "Wild Violet",
            scientificName: "Viola sororia",
            family: "Violaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Heart-shaped leaves and violet spring blooms; spreads by seed and rhizomes and is a host for fritillary larvae.",
            traits: ["Purple flowers", "Heart-shaped leaves", "Low-growing"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 82816,
            monthlyAffinity: [0.01, 0.01, 0.18, 1.0, 0.86, 0.08, 0.0, 0.01, 0.01, 0.02, 0.0, 0.0]
        ),
        CatalogPlant(
            commonName: "Queen Anne's Lace",
            scientificName: "Daucus carota",
            family: "Apiaceae",
            habitat: "meadows",
            nativeRange: "Introduced from Europe & W Asia",
            summary: "Lacy white umbels (wild carrot) with a \"bird's nest\" seed head; can be weedy and resembles toxic lookalikes.",
            traits: ["White umbels", "Carrot-scented root", "Lacy appearance"],
            defaultPlaceholder: "circle.grid.cross.fill",
            inaturalistTaxonID: 76610,
            monthlyAffinity: [0.05, 0.04, 0.05, 0.15, 0.19, 0.37, 1.0, 0.64, 0.35, 0.16, 0.07, 0.04]
        ),
        CatalogPlant(
            commonName: "Common Milkweed",
            scientificName: "Asclepias syriaca",
            family: "Apocynaceae",
            habitat: "meadows",
            nativeRange: "Native to eastern North America",
            summary: "Fragrant pink flower clusters and silky pods; vital monarch host plant and a magnet for many pollinators.",
            traits: ["Pink flower clusters", "Milky sap", "Monarch host"],
            defaultPlaceholder: "allergens.fill",
            inaturalistTaxonID: 47911,
            monthlyAffinity: [0.03, 0.02, 0.03, 0.08, 0.24, 1.0, 0.79, 0.62, 0.43, 0.25, 0.07, 0.03]
        ),
        CatalogPlant(
            commonName: "Goldenrod",
            scientificName: "Solidago canadensis",
            family: "Asteraceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Late-summer golden plumes that fuel bees; often blamed for allergies, but ragweed is the usual culprit.",
            traits: ["Yellow plumes", "Fall bloomer", "Attracts pollinators"],
            defaultPlaceholder: "sun.max.fill",
            inaturalistTaxonID: 67808,
            monthlyAffinity: [0.03, 0.02, 0.01, 0.08, 0.18, 0.23, 0.5, 1.0, 0.64, 0.29, 0.11, 0.03]
        ),
        CatalogPlant(
            commonName: "Wild Bergamot",
            scientificName: "Monarda fistulosa",
            family: "Lamiaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Lavender pom-pom blooms and minty leaves; excellent for bees and butterflies, and leaves are used as tea.",
            traits: ["Lavender flowers", "Aromatic", "Square stems"],
            defaultPlaceholder: "allergens.fill",
            inaturalistTaxonID: 85320,
            monthlyAffinity: [0.01, 0.01, 0.01, 0.05, 0.06, 0.23, 1.0, 0.31, 0.07, 0.03, 0.01, 0.01]
        ),
        CatalogPlant(
            commonName: "Bloodroot",
            scientificName: "Sanguinaria canadensis",
            family: "Papaveraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Early spring white flowers; broken rhizomes bleed orange-red sap, historically used as dye and in folk remedies.",
            traits: ["White flowers", "Red sap", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 51044,
            monthlyAffinity: [0.0, 0.01, 0.35, 1.0, 0.39, 0.08, 0.04, 0.03, 0.02, 0.01, 0.0, 0.0]
        ),
        CatalogPlant(
            commonName: "Trillium",
            scientificName: "Trillium grandiflorum",
            family: "Melanthiaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Woodland spring icon with three leaves and large white blooms aging pink; slow-growing and sensitive to picking.",
            traits: ["Three petals", "Three leaves", "White to pink"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 55402,
            monthlyAffinity: [0.0, 0.0, 0.02, 0.62, 1.0, 0.06, 0.02, 0.01, 0.0, 0.0, 0.0, 0.0]
        ),
        CatalogPlant(
            commonName: "Virginia Bluebells",
            scientificName: "Mertensia virginica",
            family: "Boraginaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Nodding blue tubular flowers in spring; thrives in floodplain woods and goes dormant by early summer.",
            traits: ["Blue bell flowers", "Pink buds", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 59771,
            monthlyAffinity: [0.0, 0.01, 0.32, 1.0, 0.23, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        ),
        CatalogPlant(
            commonName: "Joe Pye Weed",
            scientificName: "Eutrochium purpureum",
            family: "Asteraceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Tall, mauve flower heads late in season; beloved by butterflies and great for meadow-style plantings.",
            traits: ["Pink-purple dome", "Whorled leaves", "Tall stature"],
            defaultPlaceholder: "allergens.fill",
            inaturalistTaxonID: 85378,
            monthlyAffinity: [0.0, 0.0, 0.0, 0.04, 0.09, 0.22, 1.0, 0.8, 0.27, 0.07, 0.01, 0.0]
        ),
        CatalogPlant(
            commonName: "Cardinal Flower",
            scientificName: "Lobelia cardinalis",
            family: "Campanulaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Brilliant scarlet spikes along streams; a hummingbird favorite that likes consistently moist soils.",
            traits: ["Bright red spikes", "Attracts hummingbirds", "Wet areas"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 48038,
            monthlyAffinity: [0.0, 0.0, 0.0, 0.01, 0.01, 0.02, 0.29, 1.0, 0.57, 0.1, 0.01, 0.0]
        ),
        CatalogPlant(
            commonName: "Wild Geranium",
            scientificName: "Geranium maculatum",
            family: "Geraniaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Pink spring flowers and deeply cut leaves; dependable woodland perennial that supports early pollinators.",
            traits: ["Pink-purple flowers", "Deeply lobed leaves", "Crane's bill fruit"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 47699,
            monthlyAffinity: [0.0, 0.0, 0.04, 0.52, 1.0, 0.14, 0.02, 0.01, 0.01, 0.01, 0.0, 0.0]
        ),
        CatalogPlant(
            commonName: "Dutchman's Breeches",
            scientificName: "Dicentra cucullaria",
            family: "Papaveraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Delicate spring ephemeral with white \"pantaloons\"; emerges early in rich woods, then disappears by summer.",
            traits: ["White pantaloon flowers", "Ferny foliage", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 51053,
            monthlyAffinity: [0.0, 0.0, 0.22, 1.0, 0.27, 0.01, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        ),

        // SHRUBS (8)
        CatalogPlant(
            commonName: "Mountain Laurel",
            scientificName: "Kalmia latifolia",
            family: "Ericaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Evergreen shrub with glossy leaves and intricate pink-white clusters; spectacular bloom, but all parts are toxic.",
            traits: ["Pink-white cups", "Evergreen leaves", "Toxic"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 49397,
            monthlyAffinity: [0.1, 0.09, 0.19, 0.49, 1.0, 0.72, 0.12, 0.09, 0.1, 0.15, 0.12, 0.1]
        ),
        CatalogPlant(
            commonName: "Rhododendron",
            scientificName: "Rhododendron maximum",
            family: "Ericaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Large evergreen with big pink-white trusses; forms dense \"laurel hells\" in Appalachian forests and coves.",
            traits: ["Large flower clusters", "Leathery leaves", "Shade tolerant"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 83059,
            monthlyAffinity: [0.13, 0.12, 0.26, 0.35, 0.3, 0.89, 1.0, 0.19, 0.17, 0.24, 0.18, 0.15]
        ),
        CatalogPlant(
            commonName: "Elderberry",
            scientificName: "Sambucus nigra",
            family: "Adoxaceae",
            habitat: "wetlands",
            nativeRange: "Introduced from Europe to W Iran",
            summary: "Shrub/small tree with creamy flower clusters and dark berries; famous for syrups and cordials (cook berries first).",
            traits: ["White flower clusters", "Dark berries", "Compound leaves"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 765394,
            monthlyAffinity: [0.04, 0.07, 0.18, 0.72, 1.0, 0.7, 0.27, 0.37, 0.25, 0.13, 0.09, 0.05]
        ),
        CatalogPlant(
            commonName: "Spicebush",
            scientificName: "Lindera benzoin",
            family: "Lauraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Aromatic understory shrub; yellow early flowers, red berries, and leaves that host spicebush swallowtail caterpillars.",
            traits: ["Yellow flowers", "Red berries", "Aromatic twigs"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 54793,
            monthlyAffinity: [0.03, 0.06, 0.75, 1.0, 0.35, 0.49, 0.28, 0.44, 0.8, 0.43, 0.09, 0.03]
        ),
        CatalogPlant(
            commonName: "Witch Hazel",
            scientificName: "Hamamelis virginiana",
            family: "Hamamelidaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Unusual fall-blooming shrub with ribbon-like yellow petals; bark extract is widely used for skin soothing.",
            traits: ["Yellow ribbon flowers", "Fall bloomer", "Medicinal"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 51970,
            monthlyAffinity: [0.14, 0.13, 0.19, 0.41, 0.71, 0.66, 0.54, 0.45, 0.58, 1.0, 0.5, 0.21]
        ),
        CatalogPlant(
            commonName: "Winterberry",
            scientificName: "Ilex verticillata",
            family: "Aquifoliaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Deciduous holly that drops leaves to reveal bright red berries; needs male and female plants for fruit set.",
            traits: ["Red berries", "Deciduous holly", "Winter interest"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 61119,
            monthlyAffinity: [0.1, 0.03, 0.02, 0.03, 0.09, 0.45, 0.3, 0.26, 1.0, 0.94, 0.39, 0.2]
        ),
        CatalogPlant(
            commonName: "Viburnum",
            scientificName: "Viburnum dentatum",
            family: "Adoxaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Tough shrub with white spring clusters and blue-black fruit; great hedge plant that supports birds and pollinators.",
            traits: ["White flower clusters", "Blue berries", "Toothed leaves"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 82247,
            monthlyAffinity: [0.0, 0.0, 0.02, 0.81, 1.0, 0.69, 0.37, 0.46, 0.46, 0.34, 0.19, 0.02]
        ),
        CatalogPlant(
            commonName: "Buttonbush",
            scientificName: "Cephalanthus occidentalis",
            family: "Rubiaceae",
            habitat: "wetlands",
            nativeRange: "Native to North America",
            summary: "Wetland shrub with spherical \"buttons\" of flowers; excellent for bees and butterflies and thrives at pond edges.",
            traits: ["Ball-shaped flowers", "Wet feet", "Wildlife magnet"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 52763,
            monthlyAffinity: [0.04, 0.03, 0.05, 0.18, 0.26, 0.62, 1.0, 0.63, 0.49, 0.3, 0.11, 0.05]
        ),

        // FERNS & MOSSES (5)
        CatalogPlant(
            commonName: "Christmas Fern",
            scientificName: "Polystichum acrostichoides",
            family: "Dryopteridaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Evergreen fern that stays green through winter; arching fronds suit shady gardens and stabilize woodland soils.",
            traits: ["Evergreen fronds", "Stocking-shaped pinnae", "Common"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 54412,
            monthlyAffinity: [0.14, 0.14, 0.4, 1.0, 0.65, 0.4, 0.25, 0.24, 0.34, 0.36, 0.26, 0.17]
        ),
        CatalogPlant(
            commonName: "Maidenhair Fern",
            scientificName: "Adiantum pedatum",
            family: "Pteridaceae",
            habitat: "forests",
            nativeRange: "Native to North America",
            summary: "Elegant, fan-like fronds on dark stems; prefers cool, moist, rich woods and makes a striking shade accent.",
            traits: ["Fan-shaped fronds", "Black stems", "Delicate"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 48435,
            monthlyAffinity: [0.01, 0.01, 0.03, 0.38, 1.0, 0.8, 0.51, 0.47, 0.42, 0.38, 0.13, 0.03]
        ),
        CatalogPlant(
            commonName: "Ostrich Fern",
            scientificName: "Matteuccia struthiopteris",
            family: "Onocleaceae",
            habitat: "wetlands",
            nativeRange: "Native to northern North America",
            summary: "Tall vase-shaped fronds form lush colonies; edible fiddleheads in spring (cook well) and thrives in moist shade.",
            traits: ["Vase shape", "Fiddleheads edible", "Tall fronds"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 82574,
            monthlyAffinity: [0.03, 0.02, 0.05, 0.41, 1.0, 0.51, 0.33, 0.26, 0.16, 0.07, 0.03, 0.02]
        ),
        CatalogPlant(
            commonName: "Cinnamon Fern",
            scientificName: "Osmundastrum cinnamomeum",
            family: "Osmundaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Moist-woods fern with distinctive cinnamon-colored fertile fronds; excellent for rain gardens and boggy soils.",
            traits: ["Cinnamon fertile fronds", "Large clumps", "Woolly fiddleheads"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 204165,
            monthlyAffinity: [0.02, 0.02, 0.1, 0.45, 1.0, 0.78, 0.3, 0.26, 0.29, 0.22, 0.05, 0.02]
        ),
        CatalogPlant(
            commonName: "Sensitive Fern",
            scientificName: "Onoclea sensibilis",
            family: "Onocleaceae",
            habitat: "wetlands",
            nativeRange: "Native to North America",
            summary: "Named for fronds that collapse with frost; spreads readily in wet shade and features bead-like fertile fronds.",
            traits: ["Broad pinnae", "Bead-like fertile fronds", "Frost sensitive"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 82576,
            monthlyAffinity: [0.04, 0.05, 0.1, 0.54, 1.0, 0.73, 0.51, 0.44, 0.4, 0.21, 0.05, 0.03]
        ),

        // GRASSES & SEDGES (5)
        CatalogPlant(
            commonName: "Big Bluestem",
            scientificName: "Andropogon gerardii",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to central/eastern NA",
            summary: "Prairie \"king\" grass with turkey-foot seed heads; deep roots build soil and handle drought once established.",
            traits: ["Turkey foot seed heads", "Tall grass", "Prairie native"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 121968,
            monthlyAffinity: [0.05, 0.03, 0.02, 0.02, 0.02, 0.04, 0.45, 1.0, 0.85, 0.46, 0.15, 0.06]
        ),
        CatalogPlant(
            commonName: "Switchgrass",
            scientificName: "Panicum virgatum",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Clumping warm-season grass with airy seed panicles; great for wildlife cover and widely used in restoration.",
            traits: ["Airy seed heads", "Fall color", "Erosion control"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 125727,
            monthlyAffinity: [0.27, 0.25, 0.31, 0.55, 0.23, 0.19, 0.56, 0.89, 1.0, 0.88, 0.48, 0.33]
        ),
        CatalogPlant(
            commonName: "Pennsylvania Sedge",
            scientificName: "Carex pensylvanica",
            family: "Cyperaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Low, fine-textured sedge that forms a soft groundcover; a shade-tolerant lawn alternative in dry woods.",
            traits: ["Fine texture", "Shade tolerant", "Lawn alternative"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 127326,
            monthlyAffinity: [0.0, 0.0, 0.11, 1.0, 0.5, 0.1, 0.02, 0.01, 0.01, 0.01, 0.01, 0.0]
        ),
        CatalogPlant(
            commonName: "Little Bluestem",
            scientificName: "Schizachyrium scoparium",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Bunchgrass with blue-green summer blades turning copper in fall; tough, droughty-site favorite for habitat.",
            traits: ["Bronze fall color", "Fluffy seeds", "Bunch grass"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 122603,
            monthlyAffinity: [0.26, 0.18, 0.21, 0.43, 0.17, 0.12, 0.21, 0.43, 0.82, 1.0, 0.62, 0.37]
        ),
        CatalogPlant(
            commonName: "Indian Grass",
            scientificName: "Sorghastrum nutans",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to central/eastern NA",
            summary: "Tall prairie grass with golden, plume-like seed heads; excellent for screening, birds, and late-season texture.",
            traits: ["Golden plumes", "Blue-green leaves", "Tall prairie grass"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 122608,
            monthlyAffinity: [0.08, 0.06, 0.05, 0.04, 0.02, 0.02, 0.06, 0.59, 1.0, 0.59, 0.22, 0.12]
        ),

        // VINES (5)
        CatalogPlant(
            commonName: "Virginia Creeper",
            scientificName: "Parthenocissus quinquefolia",
            family: "Vitaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Fast vine with five-leaf clusters and fiery red fall color; blue berries feed birds, but sap may irritate skin.",
            traits: ["5 leaflets", "Red fall color", "Blue berries"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 50278,
            monthlyAffinity: [0.03, 0.02, 0.14, 1.0, 0.81, 0.54, 0.4, 0.37, 0.47, 0.34, 0.1, 0.04]
        ),
        CatalogPlant(
            commonName: "Poison Ivy",
            scientificName: "Toxicodendron radicans",
            family: "Anacardiaceae",
            habitat: "forests",
            nativeRange: "Native to North America",
            summary: "\"Leaves of three\" vine/shrub with urushiol oil that causes rash; berries feed birds that spread the plant.",
            traits: ["Leaves of three", "Hairy vine", "CAUTION: Causes rash"],
            defaultPlaceholder: "exclamationmark.triangle.fill",
            inaturalistTaxonID: 58732,
            monthlyAffinity: [0.06, 0.06, 0.17, 1.0, 0.94, 0.58, 0.4, 0.35, 0.44, 0.33, 0.13, 0.07]
        ),
        CatalogPlant(
            commonName: "Wild Grape",
            scientificName: "Vitis labrusca",
            family: "Vitaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Woody vine with tangy grapes and big leaves; important wildlife food and a key ancestor of some grape varieties.",
            traits: ["Lobed leaves", "Dark grapes", "Shreddy bark"],
            defaultPlaceholder: "leaf.fill",
            inaturalistTaxonID: 68053,
            monthlyAffinity: [0.01, 0.0, 0.0, 0.11, 0.47, 0.88, 1.0, 0.77, 0.68, 0.21, 0.04, 0.01]
        ),
        CatalogPlant(
            commonName: "Trumpet Vine",
            scientificName: "Campsis radicans",
            family: "Bignoniaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Vigorous vine with orange-red trumpet flowers; a hummingbird magnet, but can spread aggressively if unmanaged.",
            traits: ["Orange trumpets", "Hummingbird magnet", "Aggressive"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 75995,
            monthlyAffinity: [0.03, 0.02, 0.05, 0.43, 0.59, 1.0, 0.88, 0.65, 0.46, 0.29, 0.11, 0.04]
        ),
        CatalogPlant(
            commonName: "American Wisteria",
            scientificName: "Wisteria frutescens",
            family: "Fabaceae",
            habitat: "wetlands",
            nativeRange: "Native to SE & south-central US",
            summary: "Native wisteria with lavender flower racemes; less aggressive than Asian wisterias and good on sturdy trellises.",
            traits: ["Purple flower clusters", "Native wisteria", "Less aggressive"],
            defaultPlaceholder: "camera.fill",
            inaturalistTaxonID: 51266,
            monthlyAffinity: [0.02, 0.01, 0.13, 1.0, 0.95, 0.3, 0.21, 0.13, 0.1, 0.11, 0.03, 0.03]
        )
    ]
}
