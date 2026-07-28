import XCTest

/// Throwaway driver: walks the onboarding flow (drag a card, check one off,
/// spin the assign dial, page through) with pauses so the host can capture
/// simulator screenshots.
final class OnboardingDriverTests: XCTestCase {
    func testDriveOnboarding() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(3)

        // --- Page 1: drag a card across the screen.
        let walkDog = app.staticTexts["Walk the dog"]
        XCTAssertTrue(walkDog.waitForExistence(timeout: 5), "Onboarding page 1 not visible")
        let dragFrom = walkDog.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.5))
        let dragTo = app.coordinate(withNormalizedOffset: CGVector(dx: 0.72, dy: 0.62))
        dragFrom.press(forDuration: 0.25, thenDragTo: dragTo)
        sleep(2)

        // --- Page 1: check off a card → confetti drops from the top.
        let checkbox = app.buttons["onboarding.checkbox.Pick up milk"]
        XCTAssertTrue(checkbox.waitForExistence(timeout: 3), "Card checkbox not found")
        checkbox.tap()
        sleep(4) // confetti falls ~2.7s; host screenshots mid-fall

        // --- Page 2.
        app.buttons["Next"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["Sarah"].waitForExistence(timeout: 3))

        // Spin the dial one notch to the left → Myself snaps to center.
        let dialStart = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        dialStart.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.3)))
        sleep(3)

        // Spin two notches the other way → Victor snaps to center.
        let dialStart2 = app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.3))
        dialStart2.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.3)))
        sleep(3)

        // --- Page 3, then finish.
        app.buttons["Next"].tap()
        sleep(3)
        let addWidget = app.buttons["Add widget"]
        XCTAssertTrue(addWidget.waitForExistence(timeout: 3), "Page 3 CTA not found")
        addWidget.tap()
        sleep(4)
    }

    /// Settings → Onboarding → Restart replays the intro immediately.
    func testRestartOnboardingFromSettings() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(3)

        // If onboarding is up (fresh install), skip it first.
        if app.buttons["Skip"].waitForExistence(timeout: 2) {
            app.buttons["Skip"].tap()
            sleep(2)
        }

        XCTAssertTrue(app.staticTexts["My todo"].waitForExistence(timeout: 5))

        // Gear button (no identifier) sits top-right of the header.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.91, dy: 0.105)).tap()
        sleep(2)

        let restart = app.buttons["Restart onboarding"]
        for _ in 0..<6 where !(restart.exists && restart.isHittable) {
            app.swipeUp()
        }
        XCTAssertTrue(restart.waitForExistence(timeout: 3), "Restart onboarding row not found")
        restart.tap()
        sleep(2)

        XCTAssertTrue(
            app.staticTexts["Todos that feel delightful"].waitForExistence(timeout: 5),
            "Onboarding did not replay after restart"
        )
        sleep(2)

        // Skip returns to the app and persists completion.
        app.buttons["Skip"].tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["My todo"].waitForExistence(timeout: 5))
    }
}
