import XCTest

final class CrainPaintVisualizerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        XCUIApplication().terminate()
    }

    @MainActor
    func testLearnMoreFlowCanDismissOrEnterVisualizer() throws {
        let app = XCUIApplication()
        configureLaunch(app)
        app.launch()

        let learnMore = app.buttons["welcome.learnMore"]
        XCTAssertTrue(learnMore.waitForExistence(timeout: 5))
        XCTAssertTrue(learnMore.waitUntilHittable(timeout: 5))
        learnMore.tap()

        let howItWorksTitle = app.staticTexts["howItWorks.title"]
        XCTAssertTrue(howItWorksTitle.waitForExistence(timeout: 5))

        let backButton = app.buttons["howItWorks.back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        XCTAssertTrue(backButton.waitUntilHittable(timeout: 5))
        backButton.tap()

        XCTAssertTrue(learnMore.waitForExistence(timeout: 5))
        learnMore.tap()

        let continueButton = app.buttons["howItWorks.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        XCTAssertTrue(continueButton.waitUntilHittable(timeout: 5))
        continueButton.tap()

        XCTAssertTrue(app.buttons["home.primaryCTA"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeDraftShowsSecondaryContinueProjectRoute() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let homeCTA = app.buttons["home.primaryCTA"]
        XCTAssertTrue(homeCTA.waitUntilHittable(timeout: 5))
        XCTAssertEqual(homeCTA.label, "Start a new preview")

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        continueProject.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeWithoutDraftShowsOnlyPrimaryStartCTA() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let homeCTA = app.buttons["home.primaryCTA"]
        XCTAssertTrue(homeCTA.waitUntilHittable(timeout: 5))
        XCTAssertEqual(homeCTA.label, "Start a new preview")
        XCTAssertFalse(app.buttons["previewHome.continueProject"].exists)
    }

    @MainActor
    func testPreviewHomePrioritizesFreshStartWhileKeepingContinueProjectSecondary() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let startFresh = app.buttons["home.primaryCTA"]
        XCTAssertTrue(startFresh.waitUntilHittable(timeout: 5))
        XCTAssertEqual(startFresh.label, "Start a new preview")

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        XCTAssertEqual(continueProject.label, "Continue current project")

        startFresh.tap()

        let photoNext = app.buttons["photoUpload.nextStep"]
        XCTAssertTrue(photoNext.waitForExistence(timeout: 5))
    }

    @MainActor
    func testResultsGalleryPromotesReadyPreviewAndRemovesLargeCTAAfterCompletion() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_ALLOW_LOCAL_PREVIEW",
            "UITEST_DISABLE_ANIMATIONS",
        ], environment: [
            "UITEST_LOCAL_PREVIEW_DELAY_MS": "7000"
        ])
        app.launch()

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        continueProject.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
        generate.tap()

        let processingStatus = app.descendants(matching: .any)["results.processing.status"]
        XCTAssertTrue(app.staticTexts["Rendering your preview"].waitForExistence(timeout: 5))
        XCTAssertTrue(processingStatus.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Current Room • Full Walls"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Applying White Dove to full walls now"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Rendering continues if you leave this screen. Your preview will appear here automatically when it's ready."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["White Dove"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars.buttons["Review Project"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["0 of 1 ready"].exists)
        XCTAssertFalse(app.staticTexts["Stay on this screen while we build your preview set. Finished options will appear here automatically."].exists)
        XCTAssertFalse(app.staticTexts["Finished previews will land here automatically. Adjustments and detail views unlock once this batch is complete."].exists)

        let readyPreviewCard = app.buttons["results.readyPreviewCard"].firstMatch
        let inlineAdjust = app.buttons["results.adjustProjectInline"]

        XCTAssertTrue(readyPreviewCard.waitUntilHittable(timeout: 10))
        XCTAssertTrue(inlineAdjust.waitUntilHittable(timeout: 10))
        XCTAssertFalse(app.buttons["results.openLatest"].exists)
        XCTAssertFalse(processingStatus.exists)
        XCTAssertFalse(app.otherElements["results.jobDetails"].exists)

        readyPreviewCard.tap()
        XCTAssertTrue(app.buttons["visualizationDetail.tryAnother"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testResultsGalleryShowsReadyPreviewFirstWhileAnotherPreviewStillProcesses() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_ALLOW_LOCAL_PREVIEW",
            "UITEST_DISABLE_ANIMATIONS",
        ], environment: [
            "UITEST_LOCAL_PREVIEW_DELAY_MS": "2500"
        ])
        app.launch()

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        continueProject.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        let sherwinBrand = app.buttons["itemPicker.brand.sherwin_williams"]
        let sherwinSwatch = app.buttons["colorSwatch.sherwin_williams-SW 7029"]
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()
        XCTAssertTrue(sherwinBrand.waitUntilHittable(timeout: 5))
        sherwinBrand.tap()
        XCTAssertTrue(sherwinSwatch.waitUntilHittable(timeout: 5))
        sherwinSwatch.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
        generate.tap()

        let compactStatusTitle = app.staticTexts["Rendering continues in the background"]
        let compactStatusHelper = app.staticTexts[
            "Rendering continues if you leave this screen. Finished previews will appear here automatically."
        ]
        let readyPreviewCard = app.buttons["results.readyPreviewCard"].firstMatch

        XCTAssertTrue(readyPreviewCard.waitUntilHittable(timeout: 6))
        XCTAssertTrue(compactStatusTitle.waitForExistence(timeout: 6))
        XCTAssertTrue(compactStatusHelper.waitForExistence(timeout: 6))
        XCTAssertLessThan(readyPreviewCard.frame.minY, compactStatusTitle.frame.minY)
    }

    @MainActor
    func testResultsGalleryKeepsReadyPreviewFirstWhenAnotherPreviewFails() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_ALLOW_LOCAL_PREVIEW",
            "UITEST_DISABLE_ANIMATIONS",
        ], environment: [
            "UITEST_LOCAL_PREVIEW_DELAY_MS": "700",
            "UITEST_LOCAL_PREVIEW_FAIL_COLOR_IDS": "sherwin_williams-SW 7029"
        ])
        app.launch()

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        continueProject.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        let sherwinBrand = app.buttons["itemPicker.brand.sherwin_williams"]
        let sherwinSwatch = app.buttons["colorSwatch.sherwin_williams-SW 7029"]
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()
        XCTAssertTrue(sherwinBrand.waitUntilHittable(timeout: 5))
        sherwinBrand.tap()
        XCTAssertTrue(sherwinSwatch.waitUntilHittable(timeout: 5))
        sherwinSwatch.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
        generate.tap()

        let readyPreviewCard = app.buttons["results.readyPreviewCard"].firstMatch
        let compactStatusTitle = app.staticTexts["results.processing.compactStatusTitle"]
        let retryButton = app.buttons["Retry Preview"]

        XCTAssertTrue(readyPreviewCard.waitUntilHittable(timeout: 6))
        XCTAssertTrue(compactStatusTitle.waitForExistence(timeout: 6))
        XCTAssertEqual(compactStatusTitle.label, "One more preview needs review")
        XCTAssertTrue(app.staticTexts["Needs review"].waitForExistence(timeout: 6))
        XCTAssertLessThan(readyPreviewCard.frame.minY, compactStatusTitle.frame.minY)

        XCTAssertTrue(swipeUpToReveal(retryButton, maxSwipes: 3))
        XCTAssertTrue(retryButton.waitUntilHittable(timeout: 6))
    }

    func testVisualizerStepsKeepPrimaryTaskSurfaceAndCTAVisibleWithoutScrolling() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let continueProject = app.buttons["previewHome.continueProject"]
        XCTAssertTrue(continueProject.waitUntilHittable(timeout: 5))
        continueProject.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        let benjaminBrand = app.buttons["itemPicker.brand.benjamin_moore"]
        let sherwinBrand = app.buttons["itemPicker.brand.sherwin_williams"]
        let farrowBrand = app.buttons["itemPicker.brand.farrow_ball"]
        XCTAssertTrue(benjaminBrand.waitUntilHittable(timeout: 5))
        XCTAssertTrue(sherwinBrand.waitUntilHittable(timeout: 5))
        XCTAssertTrue(farrowBrand.waitUntilHittable(timeout: 5))

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()

        let reviewCTA = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(reviewCTA.waitUntilHittable(timeout: 5))
        reviewCTA.tap()

        let reviewSummary = app.otherElements["projectReview.summary"]
        XCTAssertTrue(reviewSummary.waitForExistence(timeout: 5))

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
    }

    @MainActor
    func testItemPickerSwitchesBrandsWithoutBlockingOnFullCatalogLoad() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let browseByBrand = app.buttons["previewHome.browseByBrand"]
        XCTAssertTrue(browseByBrand.waitUntilHittable(timeout: 5))
        browseByBrand.tap()

        let benjaminMooreSwatch = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(benjaminMooreSwatch.waitUntilHittable(timeout: 5))

        let sherwinBrand = app.buttons["itemPicker.brand.sherwin_williams"]
        XCTAssertTrue(sherwinBrand.waitUntilHittable(timeout: 5))
        sherwinBrand.tap()

        let sherwinSwatch = app.buttons["colorSwatch.sherwin_williams-SW 7029"]
        XCTAssertTrue(sherwinSwatch.waitUntilHittable(timeout: 5))
        sherwinSwatch.tap()

        let benjaminBrand = app.buttons["itemPicker.brand.benjamin_moore"]
        XCTAssertTrue(benjaminBrand.waitUntilHittable(timeout: 5))
        benjaminBrand.tap()

        XCTAssertTrue(benjaminMooreSwatch.waitUntilHittable(timeout: 5))
    }

    @MainActor
    func testItemPickerExposesCompactBrandSelectorAccessibilityState() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let browseByBrand = app.buttons["previewHome.browseByBrand"]
        XCTAssertTrue(browseByBrand.waitUntilHittable(timeout: 5))
        browseByBrand.tap()

        let selector = app.otherElements["itemPicker.brandSelector"]
        XCTAssertTrue(selector.waitForExistence(timeout: 5))

        let benjaminBrand = app.buttons["itemPicker.brand.benjamin_moore"]
        let sherwinBrand = app.buttons["itemPicker.brand.sherwin_williams"]
        XCTAssertTrue(benjaminBrand.waitUntilHittable(timeout: 5))
        XCTAssertTrue(sherwinBrand.waitUntilHittable(timeout: 5))
        XCTAssertEqual(benjaminBrand.value as? String, "Selected")
        XCTAssertEqual(sherwinBrand.value as? String, "Not selected")

        sherwinBrand.tap()

        XCTAssertEqual(sherwinBrand.value as? String, "Selected")
        XCTAssertEqual(benjaminBrand.value as? String, "Not selected")
    }

    @MainActor
    func testColorMatcherShowsCapturedSampleAnalysisAndResultsStates() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
            "UITEST_COLOR_MATCHER_MOCK",
            "UITEST_COLOR_MATCHER_SEED_SAMPLE",
        ], environment: [
            "UITEST_COLOR_MATCHER_MOCK_DELAY_MS": "1800"
        ])
        app.launch()

        openColorMatcher(in: app)

        let sampleLocked = app.staticTexts["Sample captured"]
        XCTAssertTrue(sampleLocked.waitForExistence(timeout: 5))

        let analysisBench = app.descendants(matching: .any)["colorMatcher.analysisBench"]
        XCTAssertTrue(analysisBench.waitForExistence(timeout: 5))
        XCTAssertFalse(app.descendants(matching: .any)["colorMatcher.matchesCount"].exists)
        XCTAssertFalse(app.buttons["colorMatcher.retake"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["colorMatcher.uploadDifferent"].exists)
        XCTAssertTrue(app.buttons["colorMatcher.cancelAnalysis"].waitForExistence(timeout: 5))

        let matchesCount = app.descendants(matching: .any)["colorMatcher.matchesCount"]
        XCTAssertTrue(matchesCount.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["colorMatcher.retake"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["colorMatcher.uploadDifferent"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["colorMatcher.match.benjamin_moore-2077-30"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["colorMatcher.match.sherwin_williams-SW 6840"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["colorMatcher.favorite.benjamin_moore-2077-30"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["colorMatcher.favorite.sherwin_williams-SW 6840"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testColorMatcherCanToggleFavoriteStateFromResults() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
            "UITEST_COLOR_MATCHER_MOCK",
            "UITEST_COLOR_MATCHER_SEED_SAMPLE",
        ], environment: [
            "UITEST_COLOR_MATCHER_MOCK_DELAY_MS": "1800"
        ])
        app.launch()

        openColorMatcher(in: app)

        let favoriteButton = app.buttons["colorMatcher.favorite.benjamin_moore-2077-30"]
        XCTAssertTrue(favoriteButton.waitForExistence(timeout: 5))
        XCTAssertEqual(favoriteButton.value as? String, "Not saved")

        favoriteButton.tap()
        XCTAssertEqual(favoriteButton.value as? String, "Saved")

        favoriteButton.tap()
        XCTAssertEqual(favoriteButton.value as? String, "Not saved")
    }

    @MainActor
    func testColorMatcherEntryWaitsForExplicitCameraAction() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
            "UITEST_COLOR_MATCHER_FORCE_CAMERA_UNAVAILABLE",
        ])
        app.launch()

        openColorMatcher(in: app)

        let cameraAlert = app.alerts["Camera Access Required"]
        let useCameraAgain = app.buttons["colorMatcher.useCamera"]
        let uploadPhoto = app.buttons["colorMatcher.uploadPhoto"]
        XCTAssertFalse(cameraAlert.waitForExistence(timeout: 1))
        XCTAssertTrue(useCameraAgain.waitUntilHittable(timeout: 5))
        XCTAssertEqual(useCameraAgain.label, "Use Camera")
        XCTAssertTrue(uploadPhoto.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Match a real-world color"].waitForExistence(timeout: 5))

        useCameraAgain.tap()
        XCTAssertTrue(cameraAlert.waitForExistence(timeout: 5))
        cameraAlert.buttons["Cancel"].tap()
    }

    @MainActor
    func testOnboardingToCheckoutEntryJourney() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SEED_PHOTO",
            "UITEST_ALLOW_LOCAL_PREVIEW",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let getStarted = app.buttons["welcome.getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        XCTAssertTrue(getStarted.waitUntilHittable(timeout: 5))
        getStarted.tap()

        let homeCTA = app.buttons["home.primaryCTA"]
        XCTAssertTrue(homeCTA.waitForExistence(timeout: 5))
        XCTAssertTrue(homeCTA.waitUntilHittable(timeout: 5))
        homeCTA.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitForExistence(timeout: 5))
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitForExistence(timeout: 5))
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(whiteDove.waitForExistence(timeout: 5))
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitForExistence(timeout: 5))
        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5))
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
        generate.tap()

        let readyPreviewCard = app.buttons["results.readyPreviewCard"].firstMatch
        XCTAssertTrue(readyPreviewCard.waitUntilHittable(timeout: 10))
        readyPreviewCard.tap()

        let expertTake = app.buttons["visualizationDetail.expertTake"]
        XCTAssertTrue(expertTake.waitForExistence(timeout: 5))
        expertTake.tap()

        let tabBar = app.otherElements["app.tabBar"]
        XCTAssertFalse(tabBar.waitForExistence(timeout: 1))

        let bookConsultation = app.buttons["sampleOutput.bookConsultation"]
        XCTAssertTrue(bookConsultation.waitForExistence(timeout: 5))
        XCTAssertTrue(bookConsultation.waitUntilHittable(timeout: 10))
        bookConsultation.tap()

        XCTAssertTrue(app.staticTexts["Expert Consultation"].waitForExistence(timeout: 15))
        XCTAssertFalse(tabBar.waitForExistence(timeout: 1))
    }

    @MainActor
    func testSwitchingTabsPreservesInProgressNavigationStack() throws {
        let app = XCUIApplication()
        configureLaunch(app)
        app.launch()

        let getStarted = app.buttons["welcome.getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        getStarted.tap()

        let homeCTA = app.buttons["home.primaryCTA"]
        XCTAssertTrue(homeCTA.waitForExistence(timeout: 5))
        homeCTA.tap()

        let photoNext = app.buttons["photoUpload.nextStep"]
        XCTAssertTrue(photoNext.waitForExistence(timeout: 5))

        let savedTab = app.buttons["Library"]
        XCTAssertTrue(savedTab.waitForExistence(timeout: 5))
        savedTab.tap()

        XCTAssertTrue(app.staticTexts["Library"].waitForExistence(timeout: 5))

        let homeTab = app.buttons["Preview"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()

        XCTAssertTrue(photoNext.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeOpenSavedResetsToDesignCardsSection() throws {
        let app = XCUIApplication()
        configureLaunch(app)
        app.launch()

        let getStarted = app.buttons["welcome.getStarted"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: 5))
        XCTAssertTrue(getStarted.waitUntilHittable(timeout: 5))
        getStarted.tap()

        let savedTab = app.buttons["Library"]
        XCTAssertTrue(savedTab.waitUntilHittable(timeout: 5))
        savedTab.tap()

        let colorsSegment = app.buttons["Colors"]
        XCTAssertTrue(colorsSegment.waitUntilHittable(timeout: 5))
        colorsSegment.tap()
        XCTAssertTrue(app.descendants(matching: .any)["saved.currentSection.colors"].waitForExistence(timeout: 5))

        let homeTab = app.buttons["Preview"]
        XCTAssertTrue(homeTab.waitUntilHittable(timeout: 5))
        homeTab.tap()

        let openSaved = app.buttons["home.quickAction.saved"]
        XCTAssertTrue(openSaved.waitUntilHittable(timeout: 5))
        XCTAssertTrue(openSaved.label.contains("Open Design Cards"))
        openSaved.tap()

        XCTAssertTrue(app.buttons["Design Cards"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["saved.currentSection.previews"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSavedDesignCardShowsHeroAndToolbarShareFlow() throws {
        let app = XCUIApplication()
        configureLaunch(
            app,
            arguments: [
                "UITEST_RESET_STATE",
                "UITEST_SKIP_ONBOARDING",
                "UITEST_SEED_PHOTO",
                "UITEST_ALLOW_LOCAL_PREVIEW",
                "UITEST_DISABLE_ANIMATIONS",
            ],
            environment: [
                "CRAIN_API_BASE_URL": "http://127.0.0.1:1"
            ]
        )
        app.launch()

        openFreshResultDetail(in: app)

        let beforeAfter = app.buttons["visualizationDetail.mode.beforeAfter"]
        let openDesignCard = app.buttons["visualizationDetail.openSaved"]
        XCTAssertTrue(beforeAfter.waitForExistence(timeout: 5))
        XCTAssertEqual(beforeAfter.value as? String, "selected")
        let savedStatus = app.staticTexts["visualizationDetail.savedStatus"]
        XCTAssertTrue(savedStatus.waitForExistence(timeout: 5))
        XCTAssertEqual(savedStatus.label, "Design card ready")
        XCTAssertTrue(openDesignCard.waitUntilHittable(timeout: 5))
        XCTAssertEqual(openDesignCard.label, "Open Design Card")

        openDesignCard.tap()

        let designCard = app.descendants(matching: .any)["savedPreviewDetail.designCard"]
        let summaryCard = app.descendants(matching: .any)["savedPreviewDetail.summaryCard"]
        let summaryShareButton = app.descendants(matching: .any)["savedPreviewDetail.summaryShare"]
        let shareButton = app.buttons["savedPreviewDetail.share"]
        let moreButton = app.buttons["savedPreviewDetail.more"]
        XCTAssertTrue(designCard.waitForExistence(timeout: 5))
        XCTAssertTrue(summaryCard.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["savedPreviewDetail.mode.beforeAfter"].exists)
        XCTAssertTrue(swipeUpToReveal(summaryShareButton, maxSwipes: 5))
        XCTAssertTrue(summaryShareButton.waitUntilHittable(timeout: 5))
        XCTAssertTrue(shareButton.waitUntilHittable(timeout: 5))
        XCTAssertTrue(moreButton.waitUntilHittable(timeout: 5))
        shareButton.tap()

        XCTAssertTrue(app.buttons["savedPreviewShareSheet.sharePrimary"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedPreviewShareSheet.saveToPhotos"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["savedPreviewShareSheet.copyLink"].waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.descendants(matching: .any)["savedPreviewShareSheet.designCardReady"]
                .waitForExistence(timeout: 5)
        )
        XCTAssertFalse(app.descendants(matching: .any)["savedPreviewShareSheet.previewFallback"].exists)
    }

    @MainActor
    func testSavedDesignCardReopensPreviewOnHomeTab() throws {
        let app = XCUIApplication()
        configureLaunch(
            app,
            arguments: [
                "UITEST_RESET_STATE",
                "UITEST_SKIP_ONBOARDING",
                "UITEST_SEED_PHOTO",
                "UITEST_ALLOW_LOCAL_PREVIEW",
                "UITEST_DISABLE_ANIMATIONS",
            ],
            environment: [
                "CRAIN_API_BASE_URL": "http://127.0.0.1:1"
            ]
        )
        app.launch()

        openFreshResultDetail(in: app)

        let openDesignCard = app.buttons["visualizationDetail.openSaved"]
        XCTAssertTrue(openDesignCard.waitUntilHittable(timeout: 5))
        openDesignCard.tap()

        let moreButton = app.buttons["savedPreviewDetail.more"]
        XCTAssertTrue(moreButton.waitUntilHittable(timeout: 5))
        moreButton.tap()

        let reopenPreview = app.buttons["savedPreviewDetail.edit"]
        XCTAssertTrue(reopenPreview.waitUntilHittable(timeout: 5))
        reopenPreview.tap()

        let homeTab = app.buttons["Preview"]
        XCTAssertTrue(homeTab.waitUntilSelected(timeout: 5))

        let tryAnother = app.buttons["visualizationDetail.tryAnother"]
        XCTAssertTrue(tryAnother.waitUntilHittable(timeout: 5))
        tryAnother.tap()

        XCTAssertTrue(homeTab.waitUntilSelected(timeout: 5))
        XCTAssertTrue(app.buttons["itemPicker.nextStep"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testSavedDesignCardOverflowCanOpenBeforeAfterPreview() throws {
        let app = XCUIApplication()
        configureLaunch(
            app,
            arguments: [
                "UITEST_RESET_STATE",
                "UITEST_SKIP_ONBOARDING",
                "UITEST_SEED_PHOTO",
                "UITEST_ALLOW_LOCAL_PREVIEW",
                "UITEST_DISABLE_ANIMATIONS",
            ],
            environment: [
                "CRAIN_API_BASE_URL": "http://127.0.0.1:1"
            ]
        )
        app.launch()

        openFreshResultDetail(in: app)

        let openDesignCard = app.buttons["visualizationDetail.openSaved"]
        XCTAssertTrue(openDesignCard.waitUntilHittable(timeout: 5))
        openDesignCard.tap()

        let moreButton = app.buttons["savedPreviewDetail.more"]
        XCTAssertTrue(moreButton.waitUntilHittable(timeout: 5))
        moreButton.tap()

        let saveToPhotos = app.buttons["savedPreviewDetail.saveToPhotos"]
        let openComparison = app.buttons["savedPreviewDetail.openComparison"]
        XCTAssertTrue(saveToPhotos.waitForExistence(timeout: 5))
        XCTAssertTrue(openComparison.waitUntilHittable(timeout: 5))
        openComparison.tap()

        XCTAssertTrue(app.buttons["savedPreviewComparison.mode.beforeAfter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["savedPreviewComparison.preview"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoreHomePrimaryCTAShowsConsultationPrice() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_DISABLE_ANIMATIONS",
        ])
        app.launch()

        let moreTab = app.buttons["More"]
        XCTAssertTrue(moreTab.waitUntilHittable(timeout: 5))
        moreTab.tap()

        let primaryCTA = app.buttons["more.consultation.primary"]
        XCTAssertTrue(primaryCTA.waitForExistence(timeout: 5))
        XCTAssertTrue(primaryCTA.waitUntilHittable(timeout: 5))
        XCTAssertTrue(primaryCTA.label.contains("$149"))
        XCTAssertTrue(app.buttons["more.consultation.sample"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testMoreConsultationCheckoutShowsProjectContextAndTracksPendingReport() throws {
        let app = XCUIApplication()
        configureLaunch(app, arguments: [
            "UITEST_RESET_STATE",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SEED_PHOTO",
            "UITEST_DISABLE_ANIMATIONS",
            "UITEST_MOCK_CONSULTATION_CHECKOUT_SUCCESS",
        ])
        app.launch()

        XCTAssertTrue(app.buttons["app.tab.preview"].waitUntilSelected(timeout: 5))

        let moreTab = app.buttons["app.tab.more"]
        XCTAssertTrue(moreTab.waitUntilHittable(timeout: 5))
        moreTab.tap()

        app.swipeUp()
        let primaryCTA = app.buttons["more.consultation.primary"]
        XCTAssertTrue(primaryCTA.waitUntilHittable(timeout: 5))
        primaryCTA.tap()

        XCTAssertTrue(app.staticTexts["Current Project"].waitForExistence(timeout: 5))

        let emailField = app.textFields["consultationCheckout.email"]
        XCTAssertTrue(emailField.waitUntilHittable(timeout: 5))
        emailField.tap()
        emailField.typeText("nate@example.com")

        let secureCheckout = app.buttons["consultationCheckout.submit"]
        XCTAssertTrue(secureCheckout.waitUntilHittable(timeout: 5))
        secureCheckout.tap()

        XCTAssertTrue(app.staticTexts["Purchase Complete"].waitForExistence(timeout: 5))

        let doneButton = app.buttons["consultationCheckout.successDone"]
        XCTAssertTrue(doneButton.waitUntilHittable(timeout: 5))
        doneButton.tap()

        let latestReportCard = app.buttons["more.latestReportCard"]
        XCTAssertTrue(latestReportCard.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Current Project Consultation"].waitForExistence(timeout: 5))
    }
}

private extension XCUIElement {
    func waitUntilHittable(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == true AND hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitForLabel(_ label: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", label)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitUntilSelected(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "selected == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}

private extension CrainPaintVisualizerUITests {
    func swipeUpToReveal(_ element: XCUIElement, maxSwipes: Int) -> Bool {
        if element.waitForExistence(timeout: 1), element.isHittable {
            return true
        }

        let app = XCUIApplication()
        for _ in 0..<maxSwipes {
            app.swipeUp()
            if element.waitForExistence(timeout: 1), element.isHittable {
                return true
            }
        }

        return element.exists
    }

    func configureLaunch(
        _ app: XCUIApplication,
        arguments: [String] = [
            "UITEST_RESET_STATE",
            "UITEST_DISABLE_ANIMATIONS",
        ],
        environment: [String: String] = [:]
    ) {
        app.launchArguments += arguments
        for (key, value) in environment {
            app.launchEnvironment[key] = value
        }
    }

    func openFreshResultDetail(in app: XCUIApplication) {
        app.swipeUp()
        let browseByBrand = app.buttons["previewHome.browseByBrand"]
        XCTAssertTrue(browseByBrand.waitUntilHittable(timeout: 5))
        browseByBrand.tap()

        let whiteDove = app.buttons["colorSwatch.benjamin_moore-OC-17"]
        XCTAssertTrue(whiteDove.waitUntilHittable(timeout: 5))
        whiteDove.tap()

        let itemNext = app.buttons["itemPicker.nextStep"]
        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let wallsTile = app.buttons["surfacePicker.surface.fullWalls"]
        XCTAssertTrue(wallsTile.waitUntilHittable(timeout: 5))
        wallsTile.tap()

        let surfaceNext = app.buttons["surfacePicker.visualizeNow"]
        XCTAssertTrue(surfaceNext.waitUntilHittable(timeout: 5))
        surfaceNext.tap()

        XCTAssertTrue(itemNext.waitUntilHittable(timeout: 5))
        itemNext.tap()

        let generate = app.buttons["projectReview.generate"]
        XCTAssertTrue(generate.waitUntilHittable(timeout: 5))
        generate.tap()

        let readyPreviewCard = app.buttons["results.readyPreviewCard"].firstMatch
        XCTAssertTrue(readyPreviewCard.waitUntilHittable(timeout: 10))
        readyPreviewCard.tap()
    }

    func openColorMatcher(in app: XCUIApplication) {
        let openColorMatcher = app.buttons["previewHome.matchObject"]
        XCTAssertTrue(openColorMatcher.waitUntilHittable(timeout: 5))
        openColorMatcher.tap()
    }
}
