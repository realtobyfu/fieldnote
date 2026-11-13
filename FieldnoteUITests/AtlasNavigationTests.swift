import XCTest

final class AtlasNavigationTests: XCTestCase {
    /// The launch tests run in every orientation and leave the simulator in the
    /// last one, so pin portrait rather than inherit it from an earlier run.
    override func setUp() async throws {
        await MainActor.run { XCUIDevice.shared.orientation = .portrait }
    }

    @MainActor private func launchPreview() -> XCUIApplication {
        let app = XCUIApplication()
        // Keep interactive tests independent of the simulator's preview route.
        app.launchEnvironment = [
            "FIELDNOTE_LOCAL_PREVIEW": "1", "SEED_SAMPLE_DATA": "1",
            "SEED_REGION": "none", "SEED_TAB": "", "SEED_SCREEN": "", "SEED_REVIEW": ""
        ]
        app.launch()
        XCTAssertTrue(app.buttons["tab.journal"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor func testVolumeChipAndSpecimenReturnToHerbarium() {
        let app = launchPreview()
        app.buttons["tab.herbarium"].tap()
        app.buttons["I, Trees, 2"].tap()
        XCTAssertTrue(app.staticTexts["INDEX · 2"].waitForExistence(timeout: 3))
        app.buttons["collection.specimen.Acer rubrum"].tap()
        XCTAssertTrue(app.navigationBars["Red Maple"].waitForExistence(timeout: 3))
        app.navigationBars["Red Maple"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["tab.herbarium"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["INDEX · 2"].exists)
        XCTAssertTrue(app.buttons["I, Trees, 2"].isSelected)
    }

    @MainActor func testCollectionFilterSurvivesTabSwitch() {
        let app = launchPreview()
        app.buttons["tab.herbarium"].tap()
        app.buttons["I, Trees, 2"].tap()
        XCTAssertTrue(app.staticTexts["INDEX · 2"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["collection.specimen.Acer rubrum"].isHittable)
        app.buttons["tab.journal"].tap()
        app.buttons["tab.herbarium"].tap()
        XCTAssertTrue(app.staticTexts["INDEX · 2"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["collection.specimen.Solidago canadensis"].exists)
        XCTAssertTrue(app.buttons["collection.specimen.Acer rubrum"].isHittable)
    }

    @MainActor func testCameraCancelReturnsToCollection() {
        let app = launchPreview()
        XCTAssertEqual(app.tabBars.buttons.count, 3)
        XCTAssertFalse(app.tabBars.buttons["Capture plant"].exists)
        app.buttons["tab.herbarium"].tap()
        app.buttons["tab.capture"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["tab.herbarium"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.herbarium"].isSelected)
        XCTAssertTrue(app.buttons["collection.search"].isHittable)
    }

    @MainActor func testSavingEncounterReturnsToNearbyAndUpdatesCollection() {
        let app = launchPreview()
        app.buttons["tab.nearby"].tap()
        app.buttons["tab.capture"].tap()
        XCTAssertTrue(app.buttons["Write an Entry"].waitForExistence(timeout: 5))
        app.buttons["Write an Entry"].tap()
        let name = app.textFields["Common name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Red Maple")
        app.buttons["Save Observation"].tap()
        XCTAssertTrue(app.buttons["tab.nearby"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab.nearby"].isSelected)
        app.buttons["tab.herbarium"].tap()
        XCTAssertTrue(app.buttons["Red Maple, Acer rubrum, 3 encounters"].waitForExistence(timeout: 5))
    }

    @MainActor func testWidePhotoReviewKeepsControlsWithinSheet() {
        let app = XCUIApplication()
        app.launchEnvironment = [
            "FIELDNOTE_LOCAL_PREVIEW": "1", "SEED_SAMPLE_DATA": "1", "SEED_REVIEW": "ai"
        ]
        app.launch()
        let save = app.buttons["Save Observation"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(save.isEnabled)
        // A landscape photo used to widen the whole sheet beyond the viewport.
        XCTAssertGreaterThan(save.frame.minX, app.frame.minX)
        XCTAssertLessThan(save.frame.maxX, app.frame.maxX)
        let change = app.buttons["capture.changePhoto"]
        XCTAssertTrue(change.isHittable)
        XCTAssertLessThanOrEqual(change.frame.maxX, app.frame.maxX)
        XCTAssertGreaterThanOrEqual(app.buttons["Edit details"].frame.minX, app.frame.minX)
    }

    @MainActor func testCaptureFromSpecimenPreservesReadingPosition() {
        let app = launchPreview()
        app.buttons["tab.herbarium"].tap()
        app.buttons["collection.specimen.Acer rubrum"].tap()
        XCTAssertTrue(app.navigationBars["Red Maple"].waitForExistence(timeout: 3))
        app.navigationBars["Red Maple"].buttons["Capture plant"].tap()
        XCTAssertTrue(app.buttons["Write an Entry"].waitForExistence(timeout: 5))
        app.buttons["Write an Entry"].tap()
        let name = app.textFields["Common name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Red Maple")
        app.buttons["Save Observation"].tap()
        XCTAssertTrue(app.navigationBars["Red Maple"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["SPECIMEN · 3 ENCOUNTERS"].waitForExistence(timeout: 5))
        app.navigationBars["Red Maple"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["tab.herbarium"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.herbarium"].isSelected)
    }

    @MainActor func testJournalEntryOpensSpecimenAndHistory() {
        let app = launchPreview()
        let entry = app.buttons["journal.entry.Acer rubrum"].firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 3))
        entry.tap()
        XCTAssertTrue(app.navigationBars["Red Maple"].waitForExistence(timeout: 3))
        app.navigationBars["Red Maple"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["tab.journal"].waitForExistence(timeout: 3))
        let history = app.buttons["journal.history"]
        if !history.isHittable { app.swipeUp() }
        XCTAssertTrue(history.waitForExistence(timeout: 3))
        history.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 3))
    }

    @MainActor func testProfileSettingsReturnToJournal() {
        let app = launchPreview()
        app.buttons["Profile and settings"].firstMatch.tap()
        XCTAssertTrue(app.buttons["profile.membership"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["tab.capture"].isHittable)
        app.buttons["profile.settings"].tap()
        XCTAssertTrue(app.buttons["settings.permissions"].waitForExistence(timeout: 3))
        app.buttons["settings.permissions"].tap()
        XCTAssertTrue(app.buttons["permissions.systemSettings"].waitForExistence(timeout: 3))
        app.navigationBars["Permissions & privacy"].buttons.firstMatch.tap()
        app.buttons["settings.sources"].tap()
        XCTAssertTrue(app.navigationBars["Sources & credits"].waitForExistence(timeout: 3))
        app.navigationBars["Sources & credits"].buttons.firstMatch.tap()
        app.navigationBars["Settings"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["profile.membership"].waitForExistence(timeout: 3))
        app.navigationBars["Profile"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["tab.journal"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["journal.entry.Acer rubrum"].firstMatch.isHittable)
    }

    @MainActor func testMilestoneDetailDismissesBackToMilestones() {
        let app = launchPreview()
        app.buttons["Profile and settings"].firstMatch.tap()
        let milestones = app.buttons["profile.milestones"]
        XCTAssertTrue(milestones.waitForExistence(timeout: 3))
        milestones.tap()
        let first = app.buttons["profile.milestone.first_find"]
        XCTAssertTrue(first.waitForExistence(timeout: 3))
        if !first.isHittable { app.swipeUp() }
        let milestonesProof = XCTAttachment(screenshot: app.screenshot())
        milestonesProof.name = "Profile milestones"
        milestonesProof.lifetime = .keepAlways
        add(milestonesProof)
        first.tap()
        XCTAssertTrue(app.navigationBars["Milestone"].waitForExistence(timeout: 3))
        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["Milestones"].waitForExistence(timeout: 3))
        app.navigationBars["Milestones"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 3))
        let profileProof = XCTAttachment(screenshot: app.screenshot())
        profileProof.name = "Profile"
        profileProof.lifetime = .keepAlways
        add(profileProof)
    }

    @MainActor func testEmptyProfileAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchEnvironment = ["FIELDNOTE_LOCAL_PREVIEW": "1", "SEED_SAMPLE_DATA": "0", "SEED_SCREEN": "profile"]
        app.launchArguments = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Nothing recorded yet."].exists)
        let settings = app.buttons["profile.settingsRow"]
        XCTAssertGreaterThanOrEqual(settings.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(settings.frame.maxX, app.frame.maxX)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Profile at accessibility text size"
        attachment.lifetime = .keepAlways
        add(attachment)
        // The row sits several screens down at this size; tap scrolls it into reach.
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }
}
