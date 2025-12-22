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
            traits: ["Pointed leaf lobes", "Acorns", "Fall color"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Sugar Maple",
            scientificName: "Acer saccharum",
            family: "Sapindaceae",
            habitat: "forests",
            traits: ["5-lobed leaves", "Brilliant fall color", "Maple syrup"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "White Pine",
            scientificName: "Pinus strobus",
            family: "Pinaceae",
            habitat: "forests",
            traits: ["5 needles per bundle", "Long cones", "Soft wood"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Paper Birch",
            scientificName: "Betula papyrifera",
            family: "Betulaceae",
            habitat: "forests",
            traits: ["White peeling bark", "Triangular leaves", "Catkins"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Weeping Willow",
            scientificName: "Salix babylonica",
            family: "Salicaceae",
            habitat: "wetlands",
            traits: ["Drooping branches", "Narrow leaves", "Near water"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "American Sycamore",
            scientificName: "Platanus occidentalis",
            family: "Platanaceae",
            habitat: "urban",
            traits: ["Mottled bark", "Large maple-like leaves", "Ball fruits"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Eastern Hemlock",
            scientificName: "Tsuga canadensis",
            family: "Pinaceae",
            habitat: "forests",
            traits: ["Small flat needles", "Tiny cones", "Graceful form"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Flowering Dogwood",
            scientificName: "Cornus florida",
            family: "Cornaceae",
            habitat: "forests",
            traits: ["White bracts", "Red berries", "Layered branches"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "American Elm",
            scientificName: "Ulmus americana",
            family: "Ulmaceae",
            habitat: "urban",
            traits: ["Vase shape", "Asymmetric leaves", "Samaras"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Black Cherry",
            scientificName: "Prunus serotina",
            family: "Rosaceae",
            habitat: "forests",
            traits: ["Dark bark", "White flower clusters", "Small cherries"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Red Maple",
            scientificName: "Acer rubrum",
            family: "Sapindaceae",
            habitat: "wetlands",
            traits: ["Red twigs", "V-shaped sinuses", "Brilliant red fall"],
            defaultPlaceholder: "tree.fill"
        ),
        CatalogPlant(
            commonName: "Eastern Redbud",
            scientificName: "Cercis canadensis",
            family: "Fabaceae",
            habitat: "forests",
            traits: ["Pink flowers on branches", "Heart-shaped leaves", "Spring bloomer"],
            defaultPlaceholder: "tree.fill"
        ),

        // WILDFLOWERS (15)
        CatalogPlant(
            commonName: "Black-eyed Susan",
            scientificName: "Rudbeckia hirta",
            family: "Asteraceae",
            habitat: "meadows",
            traits: ["Yellow petals", "Dark center", "Daisy-like"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Purple Coneflower",
            scientificName: "Echinacea purpurea",
            family: "Asteraceae",
            habitat: "meadows",
            traits: ["Purple petals", "Spiny center", "Medicinal"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Common Dandelion",
            scientificName: "Taraxacum officinale",
            family: "Asteraceae",
            habitat: "urban",
            traits: ["Yellow flowers", "Puffball seeds", "Rosette leaves"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Wild Violet",
            scientificName: "Viola sororia",
            family: "Violaceae",
            habitat: "forests",
            traits: ["Purple flowers", "Heart-shaped leaves", "Low-growing"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Queen Anne's Lace",
            scientificName: "Daucus carota",
            family: "Apiaceae",
            habitat: "meadows",
            traits: ["White umbels", "Carrot-scented root", "Lacy appearance"],
            defaultPlaceholder: "circle.grid.cross.fill"
        ),
        CatalogPlant(
            commonName: "Common Milkweed",
            scientificName: "Asclepias syriaca",
            family: "Apocynaceae",
            habitat: "meadows",
            traits: ["Pink flower clusters", "Milky sap", "Monarch host"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Goldenrod",
            scientificName: "Solidago canadensis",
            family: "Asteraceae",
            habitat: "meadows",
            traits: ["Yellow plumes", "Fall bloomer", "Attracts pollinators"],
            defaultPlaceholder: "sun.max.fill"
        ),
        CatalogPlant(
            commonName: "Wild Bergamot",
            scientificName: "Monarda fistulosa",
            family: "Lamiaceae",
            habitat: "meadows",
            traits: ["Lavender flowers", "Aromatic", "Square stems"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Bloodroot",
            scientificName: "Sanguinaria canadensis",
            family: "Papaveraceae",
            habitat: "forests",
            traits: ["White flowers", "Red sap", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Trillium",
            scientificName: "Trillium grandiflorum",
            family: "Melanthiaceae",
            habitat: "forests",
            traits: ["Three petals", "Three leaves", "White to pink"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Virginia Bluebells",
            scientificName: "Mertensia virginica",
            family: "Boraginaceae",
            habitat: "wetlands",
            traits: ["Blue bell flowers", "Pink buds", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Joe Pye Weed",
            scientificName: "Eutrochium purpureum",
            family: "Asteraceae",
            habitat: "wetlands",
            traits: ["Pink-purple dome", "Whorled leaves", "Tall stature"],
            defaultPlaceholder: "allergens.fill"
        ),
        CatalogPlant(
            commonName: "Cardinal Flower",
            scientificName: "Lobelia cardinalis",
            family: "Campanulaceae",
            habitat: "wetlands",
            traits: ["Bright red spikes", "Attracts hummingbirds", "Wet areas"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Wild Geranium",
            scientificName: "Geranium maculatum",
            family: "Geraniaceae",
            habitat: "forests",
            traits: ["Pink-purple flowers", "Deeply lobed leaves", "Crane's bill fruit"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "Dutchman's Breeches",
            scientificName: "Dicentra cucullaria",
            family: "Papaveraceae",
            habitat: "forests",
            traits: ["White pantaloon flowers", "Ferny foliage", "Spring ephemeral"],
            defaultPlaceholder: "camera.fill"
        ),

        // SHRUBS (8)
        CatalogPlant(
            commonName: "Mountain Laurel",
            scientificName: "Kalmia latifolia",
            family: "Ericaceae",
            habitat: "forests",
            traits: ["Pink-white cups", "Evergreen leaves", "Toxic"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Rhododendron",
            scientificName: "Rhododendron maximum",
            family: "Ericaceae",
            habitat: "forests",
            traits: ["Large flower clusters", "Leathery leaves", "Shade tolerant"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Elderberry",
            scientificName: "Sambucus nigra",
            family: "Adoxaceae",
            habitat: "wetlands",
            traits: ["White flower clusters", "Dark berries", "Compound leaves"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Spicebush",
            scientificName: "Lindera benzoin",
            family: "Lauraceae",
            habitat: "forests",
            traits: ["Yellow flowers", "Red berries", "Aromatic twigs"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Witch Hazel",
            scientificName: "Hamamelis virginiana",
            family: "Hamamelidaceae",
            habitat: "forests",
            traits: ["Yellow ribbon flowers", "Fall bloomer", "Medicinal"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Winterberry",
            scientificName: "Ilex verticillata",
            family: "Aquifoliaceae",
            habitat: "wetlands",
            traits: ["Red berries", "Deciduous holly", "Winter interest"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Viburnum",
            scientificName: "Viburnum dentatum",
            family: "Adoxaceae",
            habitat: "forests",
            traits: ["White flower clusters", "Blue berries", "Toothed leaves"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Buttonbush",
            scientificName: "Cephalanthus occidentalis",
            family: "Rubiaceae",
            habitat: "wetlands",
            traits: ["Ball-shaped flowers", "Wet feet", "Wildlife magnet"],
            defaultPlaceholder: "leaf.fill"
        ),

        // FERNS & MOSSES (5)
        CatalogPlant(
            commonName: "Christmas Fern",
            scientificName: "Polystichum acrostichoides",
            family: "Dryopteridaceae",
            habitat: "forests",
            traits: ["Evergreen fronds", "Stocking-shaped pinnae", "Common"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Maidenhair Fern",
            scientificName: "Adiantum pedatum",
            family: "Pteridaceae",
            habitat: "forests",
            traits: ["Fan-shaped fronds", "Black stems", "Delicate"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Ostrich Fern",
            scientificName: "Matteuccia struthiopteris",
            family: "Onocleaceae",
            habitat: "wetlands",
            traits: ["Vase shape", "Fiddleheads edible", "Tall fronds"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Cinnamon Fern",
            scientificName: "Osmundastrum cinnamomeum",
            family: "Osmundaceae",
            habitat: "wetlands",
            traits: ["Cinnamon fertile fronds", "Large clumps", "Woolly fiddleheads"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Sensitive Fern",
            scientificName: "Onoclea sensibilis",
            family: "Onocleaceae",
            habitat: "wetlands",
            traits: ["Broad pinnae", "Bead-like fertile fronds", "Frost sensitive"],
            defaultPlaceholder: "leaf.fill"
        ),

        // GRASSES & SEDGES (5)
        CatalogPlant(
            commonName: "Big Bluestem",
            scientificName: "Andropogon gerardii",
            family: "Poaceae",
            habitat: "meadows",
            traits: ["Turkey foot seed heads", "Tall grass", "Prairie native"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Switchgrass",
            scientificName: "Panicum virgatum",
            family: "Poaceae",
            habitat: "meadows",
            traits: ["Airy seed heads", "Fall color", "Erosion control"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Pennsylvania Sedge",
            scientificName: "Carex pensylvanica",
            family: "Cyperaceae",
            habitat: "forests",
            traits: ["Fine texture", "Shade tolerant", "Lawn alternative"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Little Bluestem",
            scientificName: "Schizachyrium scoparium",
            family: "Poaceae",
            habitat: "meadows",
            traits: ["Bronze fall color", "Fluffy seeds", "Bunch grass"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Indian Grass",
            scientificName: "Sorghastrum nutans",
            family: "Poaceae",
            habitat: "meadows",
            traits: ["Golden plumes", "Blue-green leaves", "Tall prairie grass"],
            defaultPlaceholder: "leaf.fill"
        ),

        // VINES (5)
        CatalogPlant(
            commonName: "Virginia Creeper",
            scientificName: "Parthenocissus quinquefolia",
            family: "Vitaceae",
            habitat: "forests",
            traits: ["5 leaflets", "Red fall color", "Blue berries"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Poison Ivy",
            scientificName: "Toxicodendron radicans",
            family: "Anacardiaceae",
            habitat: "forests",
            traits: ["Leaves of three", "Hairy vine", "CAUTION: Causes rash"],
            defaultPlaceholder: "exclamationmark.triangle.fill"
        ),
        CatalogPlant(
            commonName: "Wild Grape",
            scientificName: "Vitis labrusca",
            family: "Vitaceae",
            habitat: "forests",
            traits: ["Lobed leaves", "Dark grapes", "Shreddy bark"],
            defaultPlaceholder: "leaf.fill"
        ),
        CatalogPlant(
            commonName: "Trumpet Vine",
            scientificName: "Campsis radicans",
            family: "Bignoniaceae",
            habitat: "urban",
            traits: ["Orange trumpets", "Hummingbird magnet", "Aggressive"],
            defaultPlaceholder: "camera.fill"
        ),
        CatalogPlant(
            commonName: "American Wisteria",
            scientificName: "Wisteria frutescens",
            family: "Fabaceae",
            habitat: "wetlands",
            traits: ["Purple flower clusters", "Native wisteria", "Less aggressive"],
            defaultPlaceholder: "camera.fill"
        )
    ]
}
