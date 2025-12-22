//
//  TraitChip.swift
//  Fieldnote
//
//  Chip component for traits and conditions with selectable and read-only modes
//

import SwiftUI

struct TraitChip: View {
    let text: String
    let isSelected: Bool
    let isSelectable: Bool
    let action: () -> Void

    /// Read-only chip (non-selectable)
    init(_ text: String) {
        self.text = text
        self.isSelected = false
        self.isSelectable = false
        self.action = {}
    }

    /// Selectable chip
    init(_ text: String, isSelected: Bool, action: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.isSelectable = true
        self.action = action
    }

    var body: some View {
        Group {
            if isSelectable {
                Button(action: action) {
                    chipContent
                }
                .buttonStyle(.plain)
            } else {
                chipContent
            }
        }
    }

    private var chipContent: some View {
        Text(text)
            .font(FieldType.chipLabel)
            .foregroundColor(textColor)
            .padding(.horizontal, FieldSpace.sm)
            .padding(.vertical, FieldSpace.xs)
            .background(backgroundColor)
            .cornerRadius(FieldRadius.chip)
            .overlay(
                RoundedRectangle(cornerRadius: FieldRadius.chip)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        if isSelectable {
            return isSelected ? FieldColor.accent : FieldColor.surface
        } else {
            return FieldColor.botanicalTan
        }
    }

    private var textColor: Color {
        if isSelectable {
            return isSelected ? .white : FieldColor.ink
        } else {
            return FieldColor.ink
        }
    }

    private var borderColor: Color {
        if isSelectable {
            return isSelected ? FieldColor.accent : FieldColor.separator
        } else {
            return FieldColor.separator
        }
    }
}

#Preview("Read-only Chips") {
    VStack(alignment: .leading, spacing: FieldSpace.md) {
        Text("Traits")
            .font(FieldType.caption)
            .foregroundColor(FieldColor.mutedInk)

        FlowLayout(spacing: FieldSpace.xs) {
            TraitChip("Yellow flowers")
            TraitChip("Deep taproot")
            TraitChip("Rosette leaves")
            TraitChip("Milky sap")
        }

        Text("Conditions")
            .font(FieldType.caption)
            .foregroundColor(FieldColor.mutedInk)

        FlowLayout(spacing: FieldSpace.xs) {
            TraitChip("sun")
            TraitChip("dry")
            TraitChip("hot")
        }
    }
    .padding(FieldSpace.md)
    .background(FieldColor.paper)
}

#Preview("Selectable Chips") {
    SelectableChipsPreview()
}

// Preview helper for selectable state
private struct SelectableChipsPreview: View {
    @State private var selectedConditions: Set<String> = ["sun"]

    let conditions = ["sun", "shade", "wet", "dry", "snow", "windy", "hot", "cold"]

    var body: some View {
        VStack(alignment: .leading, spacing: FieldSpace.md) {
            Text("Select conditions")
                .font(FieldType.bodyEmphasized)

            FlowLayout(spacing: FieldSpace.xs) {
                ForEach(conditions, id: \.self) { condition in
                    TraitChip(
                        condition,
                        isSelected: selectedConditions.contains(condition)
                    ) {
                        if selectedConditions.contains(condition) {
                            selectedConditions.remove(condition)
                        } else {
                            selectedConditions.insert(condition)
                        }
                    }
                }
            }

            Text("Selected: \(selectedConditions.sorted().joined(separator: ", "))")
                .font(FieldType.caption)
                .foregroundColor(FieldColor.mutedInk)
        }
        .padding(FieldSpace.md)
        .background(FieldColor.paper)
    }
}

// MARK: - Flow Layout Helper

/// Simple flow layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                      y: bounds.minY + result.frames[index].minY),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
