import SwiftUI

/// iOS 26 renders a dormant bottom search affordance whenever `.searchable`
/// exists in the hierarchy. Install it only for an explicit search session so a
/// root screen's resting state has a single, reachable search entry point.
struct PresentedSearchModifier: ViewModifier {
    @Binding var text: String
    @Binding var isPresented: Bool
    var prompt = "Search plants"

    @ViewBuilder
    func body(content: Content) -> some View {
        if isPresented {
            content.searchable(
                text: $text,
                isPresented: $isPresented,
                prompt: prompt
            )
        } else {
            content
        }
    }
}
