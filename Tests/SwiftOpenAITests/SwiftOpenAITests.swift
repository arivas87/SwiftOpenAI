import XCTest
@testable import SwiftOpenAI

final class SwiftOpenAITests: XCTestCase {
    private var apiKey = ProcessInfo.processInfo.environment["API_KEY"]!
    
    func testExample() throws {
        let openAI = SwiftOpenAI(apiKey)
    }
}
