//
//  OnboardingContainerView.swift
//  Fieldnote
//
//  Container for 3-page onboarding walkthrough with vintage styling
//

import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.onboardingStore) private var onboardingStore
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            // Aged paper background
            FieldColor.agedPaper
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    OnboardingWelcomePage()
                        .tag(0)

                    OnboardingFeaturesPage()
                        .tag(1)

                    OnboardingCameraPage()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Custom page indicator + navigation
                bottomNavigation
            }
        }
        .onChange(of: currentPage) { _, newValue in
            onboardingStore.currentPage = newValue
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        VStack(spacing: FieldSpace.lg) {
            // Custom vintage page indicator
            pageIndicator

            // Navigation buttons
            HStack {
                // Back button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(FieldColor.accent)
                }
                .opacity(currentPage > 0 ? 1 : 0)
                .disabled(currentPage == 0)

                Spacer()

                // Forward button
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage += 1
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(FieldColor.accent)
                }
                .opacity(currentPage < 2 ? 1 : 0)
                .disabled(currentPage == 2)
            }
            .padding(.horizontal, FieldSpace.xl)
        }
        .padding(.bottom, FieldSpace.xl)
        .background(
            // Subtle gradient fade from content to navigation
            LinearGradient(
                colors: [FieldColor.agedPaper.opacity(0), FieldColor.agedPaper],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .offset(y: -40),
            alignment: .top
        )
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: FieldSpace.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? FieldColor.accent : FieldColor.bookBorder)
                    .frame(width: index == currentPage ? 10 : 8,
                           height: index == currentPage ? 10 : 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }
}

#Preview {
    OnboardingContainerView()
}
