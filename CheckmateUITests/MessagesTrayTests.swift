import XCTest

/// Throwaway driver: opens Messages, taps "+", opens the Checkmate tray,
/// then idles so the host can capture simulator screenshots.
final class MessagesTrayTests: XCTestCase {
    func testOpenCheckmateTray() throws {
        let messages = XCUIApplication(bundleIdentifier: "com.apple.MobileSMS")
        messages.launch()
        sleep(3)

        // Dismiss keyboard tutorial overlay if present.
        let continueButton = messages.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 2) {
            continueButton.tap()
        }

        // Open the first sample conversation.
        let firstCell = messages.cells.firstMatch
        if firstCell.waitForExistence(timeout: 5) {
            firstCell.tap()
        }
        sleep(2)

        // If the extension tray was restored from a prior session, dismiss it
        // by focusing the message field so the "+" menu can actually open.
        let messageField = messages.textFields.firstMatch.exists
            ? messages.textFields.firstMatch
            : messages.textViews.firstMatch
        if messageField.exists && messageField.isHittable {
            messageField.tap()
            sleep(2)
        }

        // Open the "+" apps menu.
        let plus = messages.buttons["Apps"].exists
            ? messages.buttons["Apps"]
            : messages.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'app' OR label CONTAINS[c] 'add'")).firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 5), "Plus/Apps button not found")
        plus.tap()
        sleep(2)

        // Scroll the apps list until Checkmate is hittable, then tap it.
        var checkmate = messages.staticTexts["Checkmate"]
        if !checkmate.exists { checkmate = messages.buttons["Checkmate"].firstMatch as XCUIElement }
        for _ in 0..<6 where !(checkmate.exists && checkmate.isHittable) {
            messages.swipeUp()
            sleep(1)
            checkmate = messages.staticTexts["Checkmate"].exists
                ? messages.staticTexts["Checkmate"]
                : messages.buttons["Checkmate"].firstMatch
        }
        XCTAssertTrue(checkmate.waitForExistence(timeout: 5), "Checkmate not found in apps menu")
        sleep(8) // window for host-side screenshot of the apps list icon
        checkmate.tap()

        // Hold the tray open for host-side screenshots.
        sleep(20)
    }
}
