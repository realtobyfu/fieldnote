import SwiftUI

private struct SpecimenNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

private struct CaptureActionKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var specimenNamespace: Namespace.ID? {
        get { self[SpecimenNamespaceKey.self] }
        set { self[SpecimenNamespaceKey.self] = newValue }
    }
    var capturePlant: (() -> Void)? {
        get { self[CaptureActionKey.self] }
        set { self[CaptureActionKey.self] = newValue }
    }
}

private struct SpecimenSourceModifier: ViewModifier {
    let id: UUID
    @Environment(\.specimenNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder func body(content: Content) -> some View {
        if let namespace, !reduceMotion {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct SpecimenDestinationModifier: ViewModifier {
    let id: UUID
    @Environment(\.specimenNamespace) private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder func body(content: Content) -> some View {
        if let namespace, !reduceMotion {
            content.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}

extension View {
    func specimenSource(_ id: UUID) -> some View { modifier(SpecimenSourceModifier(id: id)) }
    func specimenDestination(_ id: UUID) -> some View { modifier(SpecimenDestinationModifier(id: id)) }
}
