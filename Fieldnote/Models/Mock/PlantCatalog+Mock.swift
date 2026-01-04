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
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Sugar Maple",
            scientificName: "Acer saccharum",
            family: "Sapindaceae",
            habitat: "forests",
            nativeRange: "Native to NE North America",
            summary: "Iconic maple tapped for syrup; brilliant orange-red fall color and dense wood prized for floors and furniture.",
            traits: ["5-lobed leaves", "Brilliant fall color", "Maple syrup"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "White Pine",
            scientificName: "Pinus strobus",
            family: "Pinaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Tall, soft-needled pine with 5-needle bundles; valued for lumber and shelter, and a classic landscape tree.",
            traits: ["5 needles per bundle", "Long cones", "Soft wood"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Paper Birch",
            scientificName: "Betula papyrifera",
            family: "Betulaceae",
            habitat: "forests",
            nativeRange: "Native to northern North America",
            summary: "White peeling bark and airy canopy; a pioneer tree of cool forests and historically used for canoes and baskets.",
            traits: ["White peeling bark", "Triangular leaves", "Catkins"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Weeping Willow",
            scientificName: "Salix babylonica",
            family: "Salicaceae",
            habitat: "wetlands",
            nativeRange: "Introduced from East Asia",
            summary: "Graceful, drooping branches over water; widely planted ornamental but brittle wood and short-lived in storms.",
            traits: ["Drooping branches", "Narrow leaves", "Near water"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "American Sycamore",
            scientificName: "Platanus occidentalis",
            family: "Platanaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Huge riverbank tree with mottled, peeling bark; tolerant of floods and pollution, often seen in cities and parks.",
            traits: ["Mottled bark", "Large maple-like leaves", "Ball fruits"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Eastern Hemlock",
            scientificName: "Tsuga canadensis",
            family: "Pinaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Shade-loving evergreen with flat needles and small cones; forms cool, dark ravines but threatened by adelgid.",
            traits: ["Small flat needles", "Tiny cones", "Graceful form"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Flowering Dogwood",
            scientificName: "Cornus florida",
            family: "Cornaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Spring \"flowers\" are showy bracts; red berries feed birds, and it's a beloved understory tree in woodlands.",
            traits: ["White bracts", "Red berries", "Layered branches"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "American Elm",
            scientificName: "Ulmus americana",
            family: "Ulmaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Classic vase-shaped street tree once ubiquitous; many lost to Dutch elm disease, but resistant cultivars exist.",
            traits: ["Vase shape", "Asymmetric leaves", "Samaras"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Black Cherry",
            scientificName: "Prunus serotina",
            family: "Rosaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Fragrant spring blooms and dark cherries for wildlife; valuable reddish wood used in fine furniture and cabinets.",
            traits: ["Dark bark", "White flower clusters", "Small cherries"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Red Maple",
            scientificName: "Acer rubrum",
            family: "Sapindaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Highly adaptable maple with early red flowers and vivid fall color; common in wetlands, yards, and forests.",
            traits: ["Red twigs", "V-shaped sinuses", "Brilliant red fall"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Eastern Redbud",
            scientificName: "Cercis canadensis",
            family: "Fabaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Pink pea-like blooms burst on bare branches in spring; heart-shaped leaves and great as a small yard tree.",
            traits: ["Pink flowers on branches", "Heart-shaped leaves", "Spring bloomer"],
            defaultPlaceholder: "tree.fill"
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
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Purple Coneflower",
            scientificName: "Echinacea purpurea",
            family: "Asteraceae",
            habitat: "meadows",
            nativeRange: "Native to central/eastern US",
            summary: "Purple rays around a spiky cone; popular perennial for pollinators and widely used in herbal products.",
            traits: ["Purple petals", "Spiny center", "Medicinal"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Common Dandelion",
            scientificName: "Taraxacum officinale",
            family: "Asteraceae",
            habitat: "urban",
            nativeRange: "Introduced from Eurasia",
            summary: "Sunny yellow flowers become windblown seed puffs; edible greens and roots, yet a notorious lawn colonizer.",
            traits: ["Yellow flowers", "Puffball seeds", "Rosette leaves"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Wild Violet",
            scientificName: "Viola sororia",
            family: "Violaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Heart-shaped leaves and violet spring blooms; spreads by seed and rhizomes and is a host for fritillary larvae.",
            traits: ["Purple flowers", "Heart-shaped leaves", "Low-growing"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Queen Anne's Lace",
            scientificName: "Daucus carota",
            family: "Apiaceae",
            habitat: "meadows",
            nativeRange: "Introduced from Europe & W Asia",
            summary: "Lacy white umbels (wild carrot) with a \"bird's nest\" seed head; can be weedy and resembles toxic lookalikes.",
            traits: ["White umbels", "Carrot-scented root", "Lacy appearance"],
            defaultPlaceholder: "circle.grid.cross.fill"
        ),
        CatalogPlant(
            commonName: "Common Milkweed",
            scientificName: "Asclepias syriaca",
            family: "Apocynaceae",
            habitat: "meadows",
            nativeRange: "Native to eastern North America",
            summary: "Fragrant pink flower clusters and silky pods; vital monarch host plant and a magnet for many pollinators.",
            traits: ["Pink flower clusters", "Milky sap", "Monarch host"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Goldenrod",
            scientificName: "Solidago canadensis",
            family: "Asteraceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Late-summer golden plumes that fuel bees; often blamed for allergies, but ragweed is the usual culprit.",
            traits: ["Yellow plumes", "Fall bloomer", "Attracts pollinators"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Wild Bergamot",
            scientificName: "Monarda fistulosa",
            family: "Lamiaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Lavender pom-pom blooms and minty leaves; excellent for bees and butterflies, and leaves are used as tea.",
            traits: ["Lavender flowers", "Aromatic", "Square stems"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Bloodroot",
            scientificName: "Sanguinaria canadensis",
            family: "Papaveraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Early spring white flowers; broken rhizomes bleed orange-red sap, historically used as dye and in folk remedies.",
            traits: ["White flowers", "Red sap", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Trillium",
            scientificName: "Trillium grandiflorum",
            family: "Melanthiaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Woodland spring icon with three leaves and large white blooms aging pink; slow-growing and sensitive to picking.",
            traits: ["Three petals", "Three leaves", "White to pink"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Virginia Bluebells",
            scientificName: "Mertensia virginica",
            family: "Boraginaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Nodding blue tubular flowers in spring; thrives in floodplain woods and goes dormant by early summer.",
            traits: ["Blue bell flowers", "Pink buds", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Joe Pye Weed",
            scientificName: "Eutrochium purpureum",
            family: "Asteraceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Tall, mauve flower heads late in season; beloved by butterflies and great for meadow-style plantings.",
            traits: ["Pink-purple dome", "Whorled leaves", "Tall stature"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Cardinal Flower",
            scientificName: "Lobelia cardinalis",
            family: "Campanulaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Brilliant scarlet spikes along streams; a hummingbird favorite that likes consistently moist soils.",
            traits: ["Bright red spikes", "Attracts hummingbirds", "Wet areas"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Wild Geranium",
            scientificName: "Geranium maculatum",
            family: "Geraniaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Pink spring flowers and deeply cut leaves; dependable woodland perennial that supports early pollinators.",
            traits: ["Pink-purple flowers", "Deeply lobed leaves", "Crane's bill fruit"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Dutchman's Breeches",
            scientificName: "Dicentra cucullaria",
            family: "Papaveraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Delicate spring ephemeral with white \"pantaloons\"; emerges early in rich woods, then disappears by summer.",
            traits: ["White pantaloon flowers", "Ferny foliage", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
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
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Rhododendron",
            scientificName: "Rhododendron maximum",
            family: "Ericaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Large evergreen with big pink-white trusses; forms dense \"laurel hells\" in Appalachian forests and coves.",
            traits: ["Large flower clusters", "Leathery leaves", "Shade tolerant"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Elderberry",
            scientificName: "Sambucus nigra",
            family: "Adoxaceae",
            habitat: "wetlands",
            nativeRange: "Introduced from Europe to W Iran",
            summary: "Shrub/small tree with creamy flower clusters and dark berries; famous for syrups and cordials (cook berries first).",
            traits: ["White flower clusters", "Dark berries", "Compound leaves"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Spicebush",
            scientificName: "Lindera benzoin",
            family: "Lauraceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Aromatic understory shrub; yellow early flowers, red berries, and leaves that host spicebush swallowtail caterpillars.",
            traits: ["Yellow flowers", "Red berries", "Aromatic twigs"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Witch Hazel",
            scientificName: "Hamamelis virginiana",
            family: "Hamamelidaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Unusual fall-blooming shrub with ribbon-like yellow petals; bark extract is widely used for skin soothing.",
            traits: ["Yellow ribbon flowers", "Fall bloomer", "Medicinal"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Winterberry",
            scientificName: "Ilex verticillata",
            family: "Aquifoliaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Deciduous holly that drops leaves to reveal bright red berries; needs male and female plants for fruit set.",
            traits: ["Red berries", "Deciduous holly", "Winter interest"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Viburnum",
            scientificName: "Viburnum dentatum",
            family: "Adoxaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Tough shrub with white spring clusters and blue-black fruit; great hedge plant that supports birds and pollinators.",
            traits: ["White flower clusters", "Blue berries", "Toothed leaves"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Buttonbush",
            scientificName: "Cephalanthus occidentalis",
            family: "Rubiaceae",
            habitat: "wetlands",
            nativeRange: "Native to North America",
            summary: "Wetland shrub with spherical \"buttons\" of flowers; excellent for bees and butterflies and thrives at pond edges.",
            traits: ["Ball-shaped flowers", "Wet feet", "Wildlife magnet"],
            defaultPlaceholder: "leaf.fill"
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
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Maidenhair Fern",
            scientificName: "Adiantum pedatum",
            family: "Pteridaceae",
            habitat: "forests",
            nativeRange: "Native to North America",
            summary: "Elegant, fan-like fronds on dark stems; prefers cool, moist, rich woods and makes a striking shade accent.",
            traits: ["Fan-shaped fronds", "Black stems", "Delicate"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Ostrich Fern",
            scientificName: "Matteuccia struthiopteris",
            family: "Onocleaceae",
            habitat: "wetlands",
            nativeRange: "Native to northern North America",
            summary: "Tall vase-shaped fronds form lush colonies; edible fiddleheads in spring (cook well) and thrives in moist shade.",
            traits: ["Vase shape", "Fiddleheads edible", "Tall fronds"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Cinnamon Fern",
            scientificName: "Osmundastrum cinnamomeum",
            family: "Osmundaceae",
            habitat: "wetlands",
            nativeRange: "Native to eastern North America",
            summary: "Moist-woods fern with distinctive cinnamon-colored fertile fronds; excellent for rain gardens and boggy soils.",
            traits: ["Cinnamon fertile fronds", "Large clumps", "Woolly fiddleheads"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Sensitive Fern",
            scientificName: "Onoclea sensibilis",
            family: "Onocleaceae",
            habitat: "wetlands",
            nativeRange: "Native to North America",
            summary: "Named for fronds that collapse with frost; spreads readily in wet shade and features bead-like fertile fronds.",
            traits: ["Broad pinnae", "Bead-like fertile fronds", "Frost sensitive"],
            defaultPlaceholder: "leaf.fill"
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
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Switchgrass",
            scientificName: "Panicum virgatum",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Clumping warm-season grass with airy seed panicles; great for wildlife cover and widely used in restoration.",
            traits: ["Airy seed heads", "Fall color", "Erosion control"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Pennsylvania Sedge",
            scientificName: "Carex pensylvanica",
            family: "Cyperaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Low, fine-textured sedge that forms a soft groundcover; a shade-tolerant lawn alternative in dry woods.",
            traits: ["Fine texture", "Shade tolerant", "Lawn alternative"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Little Bluestem",
            scientificName: "Schizachyrium scoparium",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to North America",
            summary: "Bunchgrass with blue-green summer blades turning copper in fall; tough, droughty-site favorite for habitat.",
            traits: ["Bronze fall color", "Fluffy seeds", "Bunch grass"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Indian Grass",
            scientificName: "Sorghastrum nutans",
            family: "Poaceae",
            habitat: "meadows",
            nativeRange: "Native to central/eastern NA",
            summary: "Tall prairie grass with golden, plume-like seed heads; excellent for screening, birds, and late-season texture.",
            traits: ["Golden plumes", "Blue-green leaves", "Tall prairie grass"],
            defaultPlaceholder: "leaf.fill"
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
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Poison Ivy",
            scientificName: "Toxicodendron radicans",
            family: "Anacardiaceae",
            habitat: "forests",
            nativeRange: "Native to North America",
            summary: "\"Leaves of three\" vine/shrub with urushiol oil that causes rash; berries feed birds that spread the plant.",
            traits: ["Leaves of three", "Hairy vine", "CAUTION: Causes rash"],
            defaultPlaceholder: "exclamationmark.triangle.fill"
        ),
        CatalogPlant(
            commonName: "Wild Grape",
            scientificName: "Vitis labrusca",
            family: "Vitaceae",
            habitat: "forests",
            nativeRange: "Native to eastern North America",
            summary: "Woody vine with tangy grapes and big leaves; important wildlife food and a key ancestor of some grape varieties.",
            traits: ["Lobed leaves", "Dark grapes", "Shreddy bark"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Trumpet Vine",
            scientificName: "Campsis radicans",
            family: "Bignoniaceae",
            habitat: "urban",
            nativeRange: "Native to eastern North America",
            summary: "Vigorous vine with orange-red trumpet flowers; a hummingbird magnet, but can spread aggressively if unmanaged.",
            traits: ["Orange trumpets", "Hummingbird magnet", "Aggressive"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "American Wisteria",
            scientificName: "Wisteria frutescens",
            family: "Fabaceae",
            habitat: "wetlands",
            nativeRange: "Native to SE & south-central US",
            summary: "Native wisteria with lavender flower racemes; less aggressive than Asian wisterias and good on sturdy trellises.",
            traits: ["Purple flower clusters", "Native wisteria", "Less aggressive"],
            defaultPlaceholder: "camera.fill"
        )
    ]
}
