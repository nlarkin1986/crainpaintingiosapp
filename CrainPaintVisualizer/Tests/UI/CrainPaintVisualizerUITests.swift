import XCTest

final class CrainPaintVisualizerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testOnboardingToCheckoutEntryJourney() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "UITEST_RESET_STATE",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
        ]
        app.launch()

        let getStarted = app.buttons["welcome.getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let brandContinue = app.buttons["brandSelector.continue"]
        XCTAssertTrue(brandContinue.waitForExistence(timeout: 5))
        brandContinue.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(whiteDove.waitForExistence(timeout: 5))
        whiteDove.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitForExistence(timeout: 5))
        itemNext.tap()

        let photoNext = app.buttons["photoUpload.nextStep"]
        XCTAssertTrue(photoNext.waitForExistence(timeout: 5))
        photoNext.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitForExistence(timeout: 5))
        wallsTile.tap()

        let visualizeNow = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(visualizeNow.waitForExistence(timeout: 5))
        visualizeNow.tap()

        let reviewFeatured = app.buttons["gallery.reviewFeatured"]
        XCTAssertTrue(reviewFeatured.waitForExistence(timeout: 5))
        reviewFeatured.tap()

        let expertTake = app.buttons["visualizationDetail.expertTake"]
        XCTAssertTrue(expertTake.waitForExistence(timeout: 5))
        expertTake.tap()

        let videoButton = app.buttons["masterReport.videoButton"]
        XCTAssertTrue(videoButton.waitForExistence(timeout: 5))
        videoButton.tap()

        let bookConsultation = app.buttons["sampleOutput.bookConsultation"]
        XCTAssertTrue(bookConsultation.waitForExistence(timeout: 5))
        bookConsultation.tap()

        XCTAssertTrue(app.staticTexts["Secure Checkout"].waitForExistence(timeout: 5))
    }
}
