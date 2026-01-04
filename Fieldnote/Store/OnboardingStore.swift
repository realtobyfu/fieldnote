//
//  OnboardingStore.swift
//  Fieldnote
//
//  Manages onboarding completion state and first-capture tracking
//

import Foundation
import SwiftUI

@MainActor
@Observable
class OnboardingStore {
    // MARK: - Keys

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasCompletedFirstCapture = "hasCompletedFirstCapture"
    }

    // MARK: - Observable State

    /// Whether the user has completed the 3-page walkthrough
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    /// Whether the user has completed their first capture
    var hasCompletedFirstCapture: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedFirstCapture, forKey: Keys.hasCompletedFirstCapture)
        }
    }

    /// Current page index during onboarding (0-2)
    var currentPage: Int = 0

    // MARK: - Init

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        self.hasCompletedFirstCapture = UserDefaults.standard.bool(forKey: Keys.hasCompletedFirstCapture)
    }

    // MARK: - Computed Properties

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    var shouldShowFirstCaptureTip: Bool {
        hasCompletedOnboarding && !hasCompletedFirstCapture
    }

    // MARK: - Actions

    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentPage = 0
    }

    func completeFirstCapture() {
        hasCompletedFirstCapture = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasCompletedFirstCapture = false
        currentPage = 0
    }

    func nextPage() {
        if currentPage < 2 {
            currentPage += 1
        }
    }

    func previousPage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
}
