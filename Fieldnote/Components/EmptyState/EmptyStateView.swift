//
//  EmptyStateView.swift
//  Fieldnote
//
//  Empty state component with icon, title, and message
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionLabel: String?

    init(
        icon: String,
        title: String,
        message: String,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: FieldSpace.lg) {
            Spacer()

            VStack(spacing: FieldSpace.md) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(FieldColor.mutedInk.opacity(0.5))

                VStack(spacing: FieldSpace.xs) {
                    Text(title)
                        .font(FieldType.title3)
                        .foregroundColor(FieldColor.ink)

                    Text(message)
                        .font(FieldType.body)
                        .foregroundColor(FieldColor.mutedInk)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, FieldSpace.xl)
                }

                if let actionLabel = actionLabel, let action = action {
                    PrimaryButton(actionLabel, action: action)
                        .padding(.horizontal, FieldSpace.xl)
                        .padding(.top, FieldSpace.sm)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("No Plants") {
    EmptyStateView(
        icon: "leaf",
        title: "No Plants Yet",
        message: "Start your field journal by capturing your first plant encounter.",
        actionLabel: "Capture Plant",
        action: {
            print("Navigate to capture")
        }
    )
    .background(FieldColor.paper)
}

#Preview("No Search Results") {
    EmptyStateView(
        icon: "magnifyingglass",
        title: "No Results",
        message: "We couldn't find any plants matching your search. Try different keywords or browse all plants."
    )
    .background(FieldColor.paper)
}

#Preview("No Winter Finds") {
    EmptyStateView(
        icon: "snowflake",
        title: "No Winter Observations",
        message: "You haven't recorded any plant encounters during winter months yet."
    )
    .background(FieldColor.paper)
}
