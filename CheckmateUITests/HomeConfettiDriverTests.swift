import XCTest

/// Throwaway driver: checks off a seeded home-page card (Lottie confetti).
final class HomeConfettiDriverTests: XCTestCase {
    func testCheckOffFirstCard() throws {
        let app = XCUIApplication()
        app.launch()

        let checkbox = app.buttons["home.checkbox.Pick up milk"]
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5), "Seeded card checkbox not visible")
        sleep(1)
        checkbox.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["1 of 2 done"].waitForExistence(timeout: 5))
    }
}
