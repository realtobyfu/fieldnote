//  NewsTabDemo.swift
//  A single-file recreation of the Apple News (iOS 26) tab animations.
//
//  Requires: Xcode 26, iOS 26 deployment target. Liquid Glass, Tab(role:),
//  tabBarMinimizeBehavior, tabViewBottomAccessory, glassEffect / glassEffectID,
//  and GlassEffectContainer are all iOS 26 APIs.
//
//  How to run: make a fresh iOS app project, delete the generated
//  ContentView.swift + App file, and drop this in. (Or remove the @main App
//  at the bottom and point your existing WindowGroup at RootDemoView().)

#if DEBUG
import SwiftUI

// ============================================================================
// MARK: - Root: flip between "how Apple actually does it" and "the mechanics"
// ============================================================================

struct RootDemoView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case native = "Native (iOS 26 TabView)"
        case custom = "Custom (hand-rolled)"
        var id: Self { self }
    }
    @State private var mode: Mode = .native

    var body: some View {
        VStack(spacing: 0) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            switch mode {
            case .native: NativeNewsTabView()
            case .custom: CustomMorphingShell()
            }
        }
    }
}

// ============================================================================
// MARK: 1. THE NATIVE PATH — this is essentially what Apple News ships.
//        Every animation in your recording falls out of these four modifiers.
// ============================================================================

struct NativeNewsTabView: View {
    enum TabID: Hashable { case today, newsPlus, audio, following, search }
    @State private var selection: TabID = .today
    @State private var query = ""

    var body: some View {
        // `SwiftUI.Tab` is qualified because the app already defines `enum Tab: Int`,
        // which otherwise shadows SwiftUI's value-based Tab here.
        TabView(selection: $selection) {
            SwiftUI.Tab("Today",     systemImage: "newspaper",         value: TabID.today)     { Feed(title: "Today") }
            SwiftUI.Tab("News+",     systemImage: "square.stack.fill", value: TabID.newsPlus)  { Feed(title: "News+") }
            SwiftUI.Tab("Audio",     systemImage: "headphones",        value: TabID.audio)     { Feed(title: "Audio") }
            SwiftUI.Tab("Following", systemImage: "heart",             value: TabID.following) { Feed(title: "Following") }

            // (A) The search role makes the magnifying glass sit apart and
            //     *morph* into a search field when selected (system-driven).
            SwiftUI.Tab("Search", systemImage: "magnifyingglass", value: TabID.search, role: .search) {
                NavigationStack {
                    SearchResults(query: query)
                        .searchable(text: $query)
                        .navigationTitle("Search")
                }
            }
        }
        // (D) The accent on the selected tab's pill.
        .tint(.red)
        // (B)(C) Scroll-to-minimize + the floating bottom accessory are iOS 26-only;
        //        applied conditionally so this builds on the iOS 18 deployment floor.
        .modifier(NewsTabBarChrome())
    }
}

// ============================================================================
// MARK: 2. THE HAND-ROLLED PATH — same look, built from primitives so you can
//        see (and steal) the mechanics. Three independent techniques:
//        • matchedGeometryEffect  -> the selection pill slides between tabs
//        • GlassEffectContainer + glassEffectID -> search button ⇄ field morph
//        • onScrollGeometryChange -> drives the minimize / expand state
// ============================================================================

struct CustomMorphingShell: View {
    @State private var selection = 0
    @State private var minimized = false
    @State private var searching  = false
    @State private var query      = ""
    @FocusState private var searchFocused: Bool

    @Namespace private var glassNS   // morph namespace for the glass shapes
    @Namespace private var pillNS    // matched-geometry namespace for the pill

    private let tabs: [(String, String)] = [
        ("Today", "newspaper"),
        ("News+", "square.stack.fill"),
        ("Audio", "headphones"),
        ("Following", "heart"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // ---- scrolling content ----
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<25, id: \.self) { StoryCard(index: $0) }
                }
                .padding()
                .padding(.bottom, 96) // clear the floating bar
            }
            // Direction-aware: scrolling down minimizes, scrolling up expands.
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { oldY, newY in
                guard abs(newY - oldY) > 4, !searching else { return }
                let goingDown = newY > oldY && newY > 0
                if goingDown != minimized {
                    withAnimation(.smooth(duration: 0.30)) { minimized = goingDown }
                }
            }

            Group {
                if #available(iOS 26.0, *) {
                    floatingBar
                } else {
                    fallbackBar
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }

    /// Non-glass fallback bar for the iOS 18 floor (the glass morph is iOS 26 only).
    private var fallbackBar: some View {
        HStack(spacing: 12) {
            if !searching {
                tabCluster.background(.regularMaterial, in: .capsule)
            }
            searchElement.background(.regularMaterial, in: .capsule)
        }
        .animation(.snappy(duration: 0.34), value: searching)
    }

    // The whole bar lives in ONE GlassEffectContainer. That's what lets two
    // separate glass shapes (the tab cluster + the search element) merge and
    // split fluidly instead of cross-fading.
    @available(iOS 26.0, *)
    private var floatingBar: some View {
        GlassEffectContainer(spacing: 14) {
            HStack(spacing: 12) {
                if !searching {
                    tabCluster
                        .glassEffect(.regular, in: .capsule)
                        .glassEffectID("cluster", in: glassNS)
                }
                searchElement
                    .glassEffect(.regular.tint(searching ? .clear : .clear), in: .capsule)
                    .glassEffectID("search", in: glassNS)
            }
        }
        .animation(.snappy(duration: 0.34), value: searching)
    }

    // ---- the cluster of tab buttons, with the sliding accent pill ----
    private var tabCluster: some View {
        HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                let selected = i == selection
                HStack(spacing: 6) {
                    Image(systemName: tabs[i].1)
                        .font(.system(size: 17, weight: .semibold))
                    // Labels only when expanded — the blurReplace transition is
                    // what gives that soft "grow in" rather than a hard pop.
                    if !minimized {
                        Text(tabs[i].0)
                            .font(.system(size: 15, weight: .semibold))
                            .fixedSize()
                            .transition(.opacity.combined(with: .blurReplace))
                    }
                }
                .foregroundStyle(selected ? .red : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    if selected {
                        // Only the SELECTED tab draws the pill. Because every
                        // candidate shares id "pill" in the same namespace,
                        // SwiftUI interpolates its frame from the old tab to the
                        // new one — that's the slide. No manual offset math.
                        Capsule()
                            .fill(.red.opacity(0.16))
                            .matchedGeometryEffect(id: "pill", in: pillNS)
                    }
                }
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.32)) { selection = i }
                }
            }
        }
        .padding(6)
        .frame(height: 56)
    }

    // ---- the search element: a button that morphs into a field ----
    @ViewBuilder private var searchElement: some View {
        if searching {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Apple News", text: $query)
                    .focused($searchFocused)
                    .submitLabel(.search)
                Button {
                    query = ""
                    searchFocused = false
                    withAnimation(.snappy(duration: 0.34)) { searching = false }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
        } else {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 56, height: 56)
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy(duration: 0.34)) { searching = true }
                    searchFocused = true
                }
        }
    }
}

// ============================================================================
// MARK: - Shared filler views (not the point, just here to make it run)
// ============================================================================

struct Feed: View {
    let title: String
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(0..<25, id: \.self) { StoryCard(index: $0) }
                }
                .padding()
            }
            .navigationTitle(title)
        }
    }
}

struct StoryCard: View {
    let index: Int
    private var color: Color {
        Color(hue: Double(index % 12) / 12.0, saturation: 0.5, brightness: 0.9)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RoundedRectangle(cornerRadius: 14)
                .fill(color.gradient)
                .frame(height: 150)
                .overlay(alignment: .topLeading) {
                    Text("CBS NEWS")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(10)
                }
            Text("Top story headline number \(index + 1)")
                .font(.headline)
                .padding(.top, 10)
            Text("2h ago · 4 min read")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
    }
}

struct SearchResults: View {
    let query: String
    var body: some View {
        List {
            if query.isEmpty {
                Section("Recent Searches") {
                    ForEach(["fbi", "world cup", "wwdc"], id: \.self) { Text($0) }
                }
            } else {
                ForEach(0..<8, id: \.self) { Text("Result \($0 + 1) for “\(query)”") }
            }
        }
    }
}

struct MiniAccessory: View {
    var body: some View {
        HStack {
            Image(systemName: "waveform")
            Text("The Daily — 18 min").font(.subheadline.weight(.medium))
            Spacer()
            Image(systemName: "play.fill")
        }
        .padding(.horizontal)
    }
}

// ============================================================================
// MARK: - iOS 26 tab-bar chrome + preview
// ============================================================================

/// iOS 26-only TabView chrome (minimize-on-scroll + floating bottom accessory),
/// applied conditionally so this demo compiles on the app's iOS 18 floor.
private struct NewsTabBarChrome: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory { MiniAccessory() }
        } else {
            content
        }
    }
}

#Preview("News tab demo") {
    RootDemoView()
}
#endif
