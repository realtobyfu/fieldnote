import XCTest

final class AtlasNavigationTests: XCTestCase {
    @MainActor private func launchPreview() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["FIELDNOTE_LOCAL_PREVIEW": "1", "SEED_SAMPLE_DATA": "1"]
        app.launch()
        XCTAssertTrue(app.buttons["tab.atlas"].waitForExistence(timeout: 10))
        return app
    }

    @MainActor func testVolumeAndSpecimenReturnToContents() {
        let app = launchPreview()
        app.buttons["I, Trees, 2"].tap()
        XCTAssertTrue(app.navigationBars["Trees"].waitForExistence(timeout: 3))
        app.buttons["Red Maple, Acer rubrum, 2 encounters"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Red Maple"].waitForExistence(timeout: 3))
        app.navigationBars["Red Maple"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Trees"].waitForExistence(timeout: 3))
        app.navigationBars["Trees"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["tab.atlas"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["I, Trees, 2"].isHittable)
    }

    @MainActor func testCollectionFilterSurvivesTabSwitch() {
        let app = launchPreview()
        app.buttons["tab.collection"].tap()
        app.buttons["Trees"].tap()
        XCTAssertTrue(app.buttons["collection.specimen.Acer rubrum"].isHittable)
        app.buttons["tab.atlas"].tap()
        app.buttons["tab.collection"].tap()
        XCTAssertFalse(app.buttons["collection.specimen.Solidago canadensis"].exists)
        XCTAssertTrue(app.buttons["collection.specimen.Acer rubrum"].isHittable)
    }

    @MainActor func testCameraCancelReturnsToCollection() {
        let app = launchPreview()
        app.buttons["tab.collection"].tap()
        app.buttons["tab.capture"].tap()
        XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5))
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["tab.collection"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.collection"].isSelected)
        XCTAssertTrue(app.textFields["collection.search"].isHittable)
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
        app.buttons["tab.collection"].tap()
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
        app.buttons["tab.collection"].tap()
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
        XCTAssertTrue(app.buttons["tab.collection"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.collection"].isSelected)
    }
}
