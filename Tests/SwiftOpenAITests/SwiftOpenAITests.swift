import XCTest
@testable import SwiftOpenAI

final class SwiftOpenAITests: XCTestCase {
    let openAI = SwiftOpenAI(ProcessInfo.processInfo.environment["API_KEY"]!)
    
    override func setUp() {
        openAI.clearHistory()
    }

    func testChat() async throws {
        _ = try await openAI.chat("Me llamo Arturo Rivas")
        _ = try await openAI.chat("¿Cuál es mi nombre?")
        openAI.clearHistory()
        _ = try await openAI.chat("¿Cuál es mi nombre?")
    }
    
    func testChatStream() async throws {
        for try await result in try await openAI.chatStream("¿Qué tal estás?") {
            print(result)
        }
    }
}
