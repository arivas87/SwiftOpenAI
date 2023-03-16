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

    public func chat(_ text: String) async throws -> ChatResponse<ChatChoice> {
        let data = try await call(endPoint: .chats, withBody: ChatBody(messages: [Message(content: text)]))
        return try decoder.decode(ChatResponse.self, from: data)
    }
    
    public func chatStream(_ text: String) async throws -> AsyncThrowingMapSequence<StreamResponse, ChatResponse<ChatDeltaChoice>> {
        try await stream(endPoint: .chats, withBody: ChatBody(messages: [Message(content: text)]))
            .map({ try self.decoder.decode(ChatResponse.self, from: $0) })
    }
}

public protocol Contentable: Codable {
    var content: String? { get }
}
