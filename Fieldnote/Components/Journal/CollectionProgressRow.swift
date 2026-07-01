//
//  CollectionProgressRow.swift
//  Fieldnote
//
//  Inline collection-progress row for the Journal home (Blend redesign):
//  a ring + label surfacing how much of the regional catalog has been discovered.
//

import SwiftUI

struct CollectionProgressRow: View {
    var discovered: Int
    var total: Int
    var title: String = "Your Collection"

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return min(1, Double(discovered) / Double(total))
    }
    private var percent: Int { Int((fraction * 100).rounded()) }

    var body: some View {
        HStack(spacing: 16) {
            ring
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FieldType.title3)
                    .foregroundStyle(FieldColor.ink)
                Text("\(discovered) of \(total) regional species discovered")
                    .font(FieldType.footnote)
                    .foregroundStyle(FieldColor.mutedInk)
            }
            Spacer(minLength: FieldSpace.sm)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FieldColor.tertiaryInk)
        }
        .padding(16)
        .background(FieldColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .fieldShadow(FieldShadow.card)
    }

    private var ring: some View {
        ZStack {
            Circle().stroke(FieldColor.separator, lineWidth: 6)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    LinearGradient(
                        colors: [FieldColor.accentBright, FieldColor.accentDeep],
                        startPoint: .top, endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("\(percent)%")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(FieldColor.accentDeep)
        }
        .frame(width: 54, height: 54)
    }
}

#Preview {
    CollectionProgressRow(discovered: 48, total: 78)
        .padding()
        .background(FieldColor.canvasBottom)
}
