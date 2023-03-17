import XCTest
@testable import SwiftOpenAI

final class SwiftOpenAITests: XCTestCase {
    private var apiKey = ProcessInfo.processInfo.environment["API_KEY"]!
    
    func testStreamChat() async throws {
        let openAI = SwiftOpenAI(apiKey)
        _ = try await openAI.chat("Me llamo Arturo Rivas")
        _ = try await openAI.chat("¿Cuál es mi nombre?")
        openAI.clearHistory()
        _ = try await openAI.chat("¿Cuál es mi nombre?")
    }
}
