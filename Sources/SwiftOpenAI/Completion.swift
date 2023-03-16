import Foundation

extension SwiftOpenAI {
    
    struct CompletionBody: Codable {
        let prompt: String
    }
    
    public struct CompletionResponse: Codable {
        let choices: [CompletionChoices]
        let usage: Usage?
        
        public var text: String? { choices.first?.text }
    }
    
    struct CompletionChoices: Codable {
        let text: String
        let index: Int
        let finishReason: String?
    }
    
    public func complete(_ prompt: String) async throws -> CompletionResponse {
        let data = try await call(endPoint: .completions, withBody: CompletionBody(prompt: prompt))
        return try decoder.decode(CompletionResponse.self, from: data)
    }
    
    public func completeStream(_ prompt: String) async throws -> AsyncThrowingMapSequence<StreamResponse, CompletionResponse> {
        try await stream(endPoint: .completions, withBody: CompletionBody(prompt: prompt))
            .map({ try self.decoder.decode(CompletionResponse.self, from: $0) })
    }
}
