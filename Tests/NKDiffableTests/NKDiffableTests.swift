import XCTest
@testable import NKDiffable

final class NKDiffableTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NKDiffable().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
