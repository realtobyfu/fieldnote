//
//  JournalStatusHeader.swift
//  Fieldnote
//
//  Pinned glass status header for the Journal home (Blend redesign):
//  greeting, current streak, and the active seasonal challenge.
//  Liquid Glass on iOS 26+, opaque "modern paper" fallback below.
//

import SwiftUI

struct JournalStatusHeader: View {
    var greeting: String
    var dateLine: String
    var streak: Int
    var challengeName: String
    var challengeProgress: Int
    var challengeTarget: Int

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(dateLine.uppercased())
                        .font(FieldType.caption2)
                        .tracking(1.6)
                        .foregroundStyle(FieldColor.mutedInk)
                    Text(greeting)
                        .font(FieldType.title2)
                        .foregroundStyle(FieldColor.ink)
                }
                Spacer(minLength: FieldSpace.sm)
                StreakChip(count: streak)
            }
            ChallengeProgressBar(
                name: challengeName,
                progress: challengeProgress,
                target: challengeTarget
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .fieldGlass(in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Streak chip

private struct StreakChip: View {
    var count: Int
    var body: some View {
        // Laurel flanking the count — a refined, botanical "achievement" mark
        // for the logging streak (deliberately not the Duolingo flame).
        HStack(spacing: 4) {
            Image(systemName: "laurel.leading")
                .font(.system(size: 14, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
            Image(systemName: "laurel.trailing")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundStyle(FieldColor.ember)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(FieldColor.ember.opacity(0.13), in: Capsule())
    }
}

// MARK: - Challenge progress bar

private struct ChallengeProgressBar: View {
    var name: String
    var progress: Int
    var target: Int

    private var fraction: Double {
        guard target > 0 else { return 0 }
        return min(1, Double(progress) / Double(target))
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(name)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(FieldColor.ink)
                .fixedSize()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(FieldColor.separator)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [FieldColor.accent, FieldColor.accentDeep],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: max(6, geo.size.width * fraction))
                }
            }
            .frame(height: 6)
            Text("\(progress)/\(target)")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundStyle(FieldColor.mutedInk)
                .fixedSize()
        }
    }
}

#Preview {
    JournalStatusHeader(
        greeting: "Good morning, Toby",
        dateLine: "Tuesday · Oct 14",
        streak: 12,
        challengeName: "Autumn Challenge",
        challengeProgress: 4,
        challengeTarget: 10
    )
    .padding()
    .background(FieldColor.canvasBottom)
}
