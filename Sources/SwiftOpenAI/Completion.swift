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
}
