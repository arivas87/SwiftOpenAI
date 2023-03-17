import Foundation

extension SwiftOpenAI {
    
    struct ChatBody: Codable {
        let messages: [Message]
    }
    
    struct Message: Codable {
        var role: String? = "user"
        let content: String?
    }
    
    public struct ChatResponse<T: Contentable>: Codable {
        let choices: [T]
        let usage: Usage?
        
        public var text: String? { choices.first?.content }
    }
    
    public struct ChatChoice: Contentable {
        let message: Message
        let index: Int
        let finishReason: String?
        
        public var content: String? { message.content }
    }
    
    public struct ChatDeltaChoice: Contentable {
        let delta: Message
        let index: Int
        let finishReason: String?
        
        public var content: String? { delta.content }
    }
    
    enum ChatError: LocalizedError {
        case noChoices
        case noText(in: Contentable)
    }
}

public protocol Contentable: Codable {
    var content: String? { get }
}
