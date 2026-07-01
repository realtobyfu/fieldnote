//
//  AnimationLabView.swift
//  Fieldnote
//
//  Interactive tutorial for SwiftUI animation. Preview-only — not mounted in the app.
//  Open this file in Xcode and run the canvas preview to learn each concept.
//

#if DEBUG
import SwiftUI

// MARK: - Root

struct AnimationLabView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("1. Implicit vs Explicit") { Lesson1_ImplicitExplicit() }
                    NavigationLink("2. Animation Curves Gallery") { Lesson2_CurvesGallery() }
                    NavigationLink("3. Spring Playground") { Lesson3_SpringPlayground() }
                    NavigationLink("4. Multiple Modifiers") { Lesson4_MultipleModifiers() }
                    NavigationLink("5. Transaction Keys") { Lesson5_TransactionKeys() }
                    NavigationLink("6. CustomAnimation") { Lesson6_CustomAnimation() }
                } header: {
                    Text("Lessons")
                } footer: {
                    Text("Each lesson is interactive — tap, drag, and observe. Code is shown below every demo.")
                        .font(FieldType.footnote)
                }
            }
            .navigationTitle("Animation Lab")
            .background(FieldColor.paper)
        }
    }
}

// MARK: - Shared Scaffold

private struct LessonScaffold<Demo: View, Controls: View>: View {
    let title: String
    let description: String
    let code: String
    @ViewBuilder var demo: () -> Demo
    @ViewBuilder var controls: () -> Controls

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FieldSpace.md) {
                Text(description)
                    .font(FieldType.body)
                    .foregroundColor(FieldColor.vintageInk)

                demo()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FieldSpace.lg)
                    .background(FieldColor.surface)
                    .cornerRadius(FieldRadius.card)

                controls()

                CodeBlock(code: code)
            }
            .padding(FieldSpace.md)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(FieldColor.paper)
    }
}

private struct CodeBlock: View {
    let code: String

    var body: some View {
        Text(code)
            .font(.system(.footnote, design: .monospaced))
            .foregroundColor(FieldColor.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(FieldSpace.sm)
            .background(FieldColor.agedPaper)
            .cornerRadius(FieldRadius.button)
    }
}

private struct Caption: View {
    let text: String
    var body: some View {
        Text(text)
            .font(FieldType.caption)
            .foregroundColor(FieldColor.fadedInk)
            .multilineTextAlignment(.center)
    }
}

// MARK: - Lesson 1 — Implicit vs Explicit

private struct Lesson1_ImplicitExplicit: View {
    @State private var selectedA = false
    @State private var selectedB = false

    var body: some View {
        LessonScaffold(
            title: "1. Implicit vs Explicit",
            description: "Tap each circle. The left toggles state directly — the view snaps to the new size. The right wraps the toggle in `withAnimation`, so SwiftUI interpolates between frames. Same end state, very different feel.",
            code: """
            // Left — snaps
            Circle()
                .scaleEffect(selected ? 1.5 : 1.0)
                .onTapGesture { selected.toggle() }

            // Right — animates
            Circle()
                .scaleEffect(selected ? 1.5 : 1.0)
                .onTapGesture {
                    withAnimation { selected.toggle() }
                }
            """,
            demo: {
                HStack(spacing: FieldSpace.xl) {
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 60, height: 60)
                            .scaleEffect(selectedA ? 1.5 : 1.0)
                            .onTapGesture { selectedA.toggle() }
                        Caption(text: "no animation")
                    }
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 60, height: 60)
                            .scaleEffect(selectedB ? 1.5 : 1.0)
                            .animation(.default, value: selectedB)
                            .onTapGesture {
                                withAnimation { selectedB.toggle() }
                            }
                        
                        Caption(text: "withAnimation")
                    }
                }
            },
            controls: {
                Button("Reset") {
                    selectedA = false
                    selectedB = false
                }
                .buttonStyle(.bordered)
            }
        )
    }
}

// MARK: - Lesson 2 — Animation Curves Gallery

private struct Lesson2_CurvesGallery: View {
    @State private var selected = false
    @State private var curve: NamedCurve = .bouncy

    enum NamedCurve: String, CaseIterable, Identifiable {
        case linear, easeInOut, spring, bouncy, smooth, snappy
        var id: String { rawValue }

        var animation: Animation {
            switch self {
            case .linear:    return .linear(duration: 0.6)
            case .easeInOut: return .easeInOut(duration: 0.6)
            case .spring:    return .spring
            case .bouncy:    return .bouncy
            case .smooth:    return .smooth
            case .snappy:    return .snappy
            }
        }
    }

    var body: some View {
        LessonScaffold(
            title: "2. Curves Gallery",
            description: "Pick a curve, then tap Toggle. `.linear` and `.easeInOut` are time-based — they always finish in the duration you specify. `.spring`, `.bouncy`, `.smooth`, `.snappy` are physics-based — they describe how the system *settles*, not how long it takes.",
            code: """
            withAnimation(\(curve.rawValue)) {
                selected.toggle()
            }
            """,
            demo: {
                Circle()
                    .fill(FieldColor.accent)
                    .frame(width: 80, height: 80)
                    .scaleEffect(selected ? 1.5 : 1.0)
                    .offset(x: selected ? 60 : -60)
            },
            controls: {
                VStack(spacing: FieldSpace.sm) {
                    Picker("Curve", selection: $curve) {
                        ForEach(NamedCurve.allCases) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("Toggle") {
                        withAnimation(curve.animation) {
                            selected.toggle()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FieldColor.accent)
                }
            }
        )
    }
}

// MARK: - Lesson 3 — Spring Playground

private struct Lesson3_SpringPlayground: View {
    @State private var selected = false
    @State private var duration: Double = 0.6
    @State private var bounce: Double = 0.3

    private var modelSpring: Spring {
        Spring(duration: duration, bounce: bounce)
    }

    var body: some View {
        LessonScaffold(
            title: "3. Spring Playground",
            description: "`Spring` is two things: an animation curve, and a *model* you can sample. Drag the sliders and watch both the live demo and the numerical readout. Negative bounce overshoots less; bounce above 0 visibly oscillates.",
            code: """
            let spring = Spring(duration: \(String(format: "%.2f", duration)),
                                bounce:   \(String(format: "%.2f", bounce)))

            // Sample the model directly:
            spring.value(target: 1, time: 0.25)

            // Or use it as an Animation:
            withAnimation(.spring(duration: \(String(format: "%.2f", duration)),
                                  bounce: \(String(format: "%.2f", bounce)))) {
                selected.toggle()
            }
            """,
            demo: {
                Circle()
                    .fill(FieldColor.accent)
                    .frame(width: 70, height: 70)
                    .offset(x: selected ? 80 : -80)
                    .onTapGesture {
                        withAnimation(.spring(duration: duration, bounce: bounce)) {
                            selected.toggle()
                        }
                    }
            },
            controls: {
                VStack(alignment: .leading, spacing: FieldSpace.sm) {
                    Text("duration: \(String(format: "%.2f", duration))s")
                        .font(FieldType.footnote)
                    Slider(value: $duration, in: 0.1...2.0)

                    Text("bounce: \(String(format: "%.2f", bounce))")
                        .font(FieldType.footnote)
                    Slider(value: $bounce, in: -0.5...0.7)

                    Button("Toggle") {
                        withAnimation(.spring(duration: duration, bounce: bounce)) {
                            selected.toggle()
                        }
                    }
                    .buttonStyle(.bordered)

                    Divider().padding(.vertical, FieldSpace.xs)

                    Text("Spring model — sampled values")
                        .font(FieldType.sectionHeader)
                        .foregroundColor(FieldColor.fadedInk)
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                        let t = fraction * duration
                        let v = modelSpring.value(target: 1.0, time: t)
                        Text("value(target: 1, time: \(String(format: "%.2f", t))s) = \(String(format: "%+.3f", v))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(FieldColor.mutedInk)
                    }
                }
            }
        )
    }
}

// MARK: - Lesson 4 — Multiple Modifiers (order & scope)

private struct Lesson4_MultipleModifiers: View {
    @State private var selected = false

    var body: some View {
        LessonScaffold(
            title: "4. Multiple Modifiers",
            description: "All three avatars share the same `selected` state and toggle together. They differ only in *how* their animation modifiers are written. A: one modifier — both shadow and scale share the curve. B: two stacked `.animation(_:value:)` — each only animates the modifiers *above* it. C: scoped `.animation { $0.modifier }` — same effect as B but the scope is explicit instead of positional.",
            code: """
            // A — single modifier (both bouncy)
            Circle()
                .shadow(radius: selected ? 12 : 0)
                .scaleEffect(selected ? 1.4 : 1.0)
                .animation(.bouncy, value: selected)

            // B — stacked modifiers (positional scope)
            Circle()
                .shadow(radius: selected ? 12 : 0)
                .animation(.smooth, value: selected)   // shadow only
                .scaleEffect(selected ? 1.4 : 1.0)
                .animation(.bouncy, value: selected)   // scale only

            // C — scoped closures (explicit scope)
            Circle()
                .animation(.smooth)  { $0.shadow(radius: selected ? 12 : 0) }
                .animation(.bouncy)  { $0.scaleEffect(selected ? 1.4 : 1.0) }
            """,
            demo: {
                HStack(alignment: .top, spacing: FieldSpace.lg) {
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 60, height: 60)
                            .shadow(radius: selected ? 12 : 0)
                            .scaleEffect(selected ? 1.4 : 1.0)
                            .animation(.bouncy, value: selected)
                        Caption(text: "A\nshared bouncy")
                    }
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 60, height: 60)
                            .shadow(radius: selected ? 12 : 0)
                            .animation(.smooth, value: selected)
                            .scaleEffect(selected ? 1.4 : 1.0)
                            .animation(.bouncy, value: selected)
                        Caption(text: "B\nshadow smooth\nscale bouncy")
                    }
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 60, height: 60)
                            .animation(.smooth) {
                                $0.shadow(radius: selected ? 12 : 0)
                            }
                            .animation(.bouncy) {
                                $0.scaleEffect(selected ? 1.4 : 1.0)
                            }
                        Caption(text: "C\nscoped\nclosures")
                    }
                }
            },
            controls: {
                Button("Toggle all three") {
                    selected.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(FieldColor.accent)
            }
        )
    }
}

// MARK: - Lesson 5 — Transaction Keys

private struct UserTappedKey: TransactionKey {
    static let defaultValue = false
}

private extension Transaction {
    var userTapped: Bool {
        get { self[UserTappedKey.self] }
        set { self[UserTappedKey.self] = newValue }
    }
}

private struct Lesson5_TransactionKeys: View {
    @State private var selected = false

    var body: some View {
        LessonScaffold(
            title: "5. Transaction Keys",
            description: "The two buttons toggle the *same* state, but the result feels different. The transaction modifier reads a custom key (`userTapped`) and picks `.bouncy` for direct user input or `.smooth` for everything else. This is how you make animation depend on *cause*, not on *value*.",
            code: """
            private struct UserTappedKey: TransactionKey {
                static let defaultValue = false
            }

            extension Transaction {
                var userTapped: Bool {
                    get { self[UserTappedKey.self] }
                    set { self[UserTappedKey.self] = newValue }
                }
            }

            Circle()
                .scaleEffect(selected ? 1.4 : 1.0)
                .transaction(value: selected) {
                    $0.animation = $0.userTapped ? .bouncy : .smooth
                }

            Button("User tap") {
                withTransaction(\\.userTapped, true) {
                    selected.toggle()
                }
            }

            Button("Server sync") {
                selected.toggle()   // no key → smooth
            }
            """,
            demo: {
                Circle()
                    .fill(FieldColor.accent)
                    .frame(width: 80, height: 80)
                    .scaleEffect(selected ? 1.4 : 1.0)
                    .transaction(value: selected) { t in
                        t.animation = t.userTapped ? .bouncy : .smooth
                    }
            },
            controls: {
                VStack(spacing: FieldSpace.sm) {
                    Button("User tap (bouncy)") {
                        withTransaction(\.userTapped, true) {
                            selected.toggle()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(FieldColor.accent)

                    Button("Server sync (smooth)") {
                        selected.toggle()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
            }
        )
    }
}

// MARK: - Lesson 6 — CustomAnimation

private struct MyLinearAnimation: CustomAnimation {
    var duration: TimeInterval

    func animate<V: VectorArithmetic>(
        value: V, time: TimeInterval, context: inout AnimationContext<V>
    ) -> V? {
        if time <= duration {
            return value.scaled(by: time / duration)
        } else {
            return nil
        }
    }

    func velocity<V: VectorArithmetic>(
        value: V, time: TimeInterval, context: AnimationContext<V>
    ) -> V? {
        value.scaled(by: 1.0 / duration)
    }
}

private struct MyQuadraticAnimation: CustomAnimation {
    var duration: TimeInterval

    func animate<V: VectorArithmetic>(
        value: V, time: TimeInterval, context: inout AnimationContext<V>
    ) -> V? {
        if time <= duration {
            let t = time / duration
            return value.scaled(by: t * t)
        } else {
            return nil
        }
    }
}

private struct Lesson6_CustomAnimation: View {
    @State private var selected = false

    var body: some View {
        LessonScaffold(
            title: "6. CustomAnimation",
            description: "`CustomAnimation` lets you author your own curve. The middle avatar uses a hand-rolled `MyLinearAnimation` — it should look identical to the built-in `.linear` on the left, because it implements the same math. The right avatar uses a quadratic curve (`t * t`) — slow start, fast finish — to show how the curve function shapes motion.",
            code: """
            struct MyLinearAnimation: CustomAnimation {
                var duration: TimeInterval

                func animate<V: VectorArithmetic>(
                    value: V, time: TimeInterval,
                    context: inout AnimationContext<V>
                ) -> V? {
                    if time <= duration {
                        value.scaled(by: time / duration)
                    } else {
                        nil  // animation finished
                    }
                }

                func velocity<V: VectorArithmetic>(
                    value: V, time: TimeInterval,
                    context: AnimationContext<V>
                ) -> V? {
                    value.scaled(by: 1.0 / duration)
                }
            }

            // Use it:
            .animation(Animation(MyLinearAnimation(duration: 1.0)),
                       value: selected)
            """,
            demo: {
                HStack(alignment: .top, spacing: FieldSpace.lg) {
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 50, height: 50)
                            .offset(x: selected ? 40 : -40)
                            .animation(.linear(duration: 1.0), value: selected)
                        Caption(text: ".linear\n(built-in)")
                    }
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.accent)
                            .frame(width: 50, height: 50)
                            .offset(x: selected ? 40 : -40)
                            .animation(Animation(MyLinearAnimation(duration: 1.0)), value: selected)
                        Caption(text: "MyLinear\n(custom)")
                    }
                    VStack(spacing: FieldSpace.sm) {
                        Circle()
                            .fill(FieldColor.botanicalBrown)
                            .frame(width: 50, height: 50)
                            .offset(x: selected ? 40 : -40)
                            .animation(Animation(MyQuadraticAnimation(duration: 1.0)), value: selected)
                        Caption(text: "MyQuadratic\nt × t")
                    }
                }
            },
            controls: {
                Button("Toggle") {
                    selected.toggle()
                }
                .buttonStyle(.borderedProminent)
                .tint(FieldColor.accent)
            }
        )
    }
}

// MARK: - Previews

#Preview("Animation Lab") {
    AnimationLabView()
}

#Preview("Lesson 1 — Implicit vs Explicit") {
    NavigationStack { Lesson1_ImplicitExplicit() }
}

#Preview("Lesson 2 — Curves Gallery") {
    NavigationStack { Lesson2_CurvesGallery() }
}

#Preview("Lesson 3 — Spring Playground") {
    NavigationStack { Lesson3_SpringPlayground() }
}

#Preview("Lesson 4 — Multiple Modifiers") {
    NavigationStack { Lesson4_MultipleModifiers() }
}

#Preview("Lesson 5 — Transaction Keys") {
    NavigationStack { Lesson5_TransactionKeys() }
}

#Preview("Lesson 6 — CustomAnimation") {
    NavigationStack { Lesson6_CustomAnimation() }
}
#endif
