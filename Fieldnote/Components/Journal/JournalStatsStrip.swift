//
//  JournalStatsStrip.swift
//  Fieldnote
//
//  Compact "at a glance" totals for the Journal home (Blend redesign):
//  species logged, total sightings, and distinct places. Gives the journal a
//  sense of accomplishment between the status header and the recent-finds feed.
//

import SwiftUI

struct JournalStatsStrip: View {
    var species: Int
    var sightings: Int
    var places: Int

    var body: some View {
        HStack(spacing: 0) {
            stat(value: species, label: "Species", icon: "leaf.fill")
            divider
            stat(value: sightings, label: "Sightings", icon: "camera.fill")
            divider
            stat(value: places, label: "Places", icon: "mappin.and.ellipse")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .fieldShadow(FieldShadow.card)
    }

    private func stat(value: Int, label: String, icon: String) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(FieldColor.ink)
                .contentTransition(.numericText())
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .semibold))
                Text(label.uppercased())
                    .font(.system(size: 10.5, weight: .semibold))
                    .tracking(0.7)
            }
            .foregroundStyle(FieldColor.mutedInk)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(FieldColor.separator)
            .frame(width: 1, height: 34)
    }
}

#Preview {
    JournalStatsStrip(species: 12, sightings: 24, places: 5)
        .padding()
        .background(FieldColor.canvasBottom)
}
