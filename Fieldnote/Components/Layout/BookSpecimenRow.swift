import SwiftUI

/// Utility pages reachable from every root tab's stack.
enum BookUtilityRoute: Hashable {
    case history, map, profile
}

/// One specimen in an index: plate, name, scientific name, encounter count.
struct BookSpecimenRow: View {
    let plant: Plant
    var body: some View {
        HStack(spacing: 18) {
            BookPlantImage(plant: plant).frame(width: 72, height: 88).specimenSource(plant.id)
            VStack(alignment: .leading, spacing: 5) {
                Text(plant.commonName).font(FieldBook.name)
                Text(plant.scientificName).font(FieldBook.scientificSmall).foregroundStyle(FieldColor.mutedInk)
                Text(FieldBook.encounterCount(plant.encounterCount)).font(.caption).foregroundStyle(FieldBook.cover)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(FieldColor.mutedInk)
        }
        .foregroundStyle(FieldColor.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
