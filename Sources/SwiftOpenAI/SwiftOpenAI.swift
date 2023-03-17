import Foundation
import OSLog

/// This type lets you interect with GPT API by [OpenAI](https://openai.com) in a reliable but flexible way
public class SwiftOpenAI {
    
    public typealias StreamResponse = AsyncCompactMapSequence<AsyncLineSequence<URLSession.AsyncBytes>, Data>
    public typealias ChatStreamResponse = AsyncCompactMapSequence<AsyncThrowingMapSequence<StreamResponse, ChatResponse<ChatDeltaChoice>>, String>
    
    private let apiKey: String
    
    private let session = URLSession.shared
    private let baseUrl = URL(string: "https://api.openai.com/v1")!
    
    public var model: Model?
    public var temperature: Int?
    public var maxTokens: Int?
    
    /// The only available `init` method because token it is a required parameter to interact with the API
    /// - Parameter apiKey: API key provided by the API and avaible in your user settings when register on platform
    /// - Parameter model: OpenAI models to use. Check [model endpoint compatibility](https://platform.openai.com/docs/models/model-endpoint-compatibility).
    public init(_ apiKey: String) {
        self.apiKey = apiKey
    }
    
    var headers: [String: String] {[
        "Authorization": "Bearer \(apiKey)",
        "Content-Type": "application/json"
    ]}
    
    private var history: [Message] = []
    
    public func clearHistory() { history.removeAll() }
    
    private func add(message: Message) {
        history.append(message)
    }
    
    public func historical() -> [String] {
        history.compactMap(\.content)
    }
    
    private func request(to endPoint: EndPoint, withBody body: Codable, stream: Bool = false) throws -> URLRequest {
        let model = self.model ?? endPoint.models.first! // Use default model if not defined
        
        let requestBody = RequestBody(
            model: model, maxTokens: maxTokens, temperature: temperature, stream: stream,
            body: body)
        
        var request = URLRequest(url: baseUrl.appendingPathComponent(endPoint.folder, isDirectory: false))
        Logger.network.debug("Request: \(request.url!)")
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try JSONEncoder.api.encode(requestBody)
        Logger.network.info("Body: \(String(data: request.httpBody!, encoding: .utf8)!)")
        
        return request
    }
    
    private func stream(endPoint: EndPoint, withBody body: Codable) async throws -> StreamResponse {
        let request = try request(to: endPoint, withBody: body, stream: true)
        
        let (result, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidURLReponseType }

        switch httpResponse.statusCode {
        case 200: return result.lines.compactMap({ line in
            Logger.network.debug("Response: \(line)")
            guard !line.contains("[DONE]") else { return nil }
            return line.hasPrefix("data: ") ? line.dropFirst(6).data(using: .utf8) : nil
        })
        default:
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            Logger.network.error("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            throw APIError.responseError(statusCode: httpResponse.statusCode, description: errorText)
        }
    }
    
    private func call(endPoint: EndPoint, withBody body: Codable) async throws -> Data {
        let request = try request(to: endPoint, withBody: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidURLReponseType }

        switch httpResponse.statusCode {
        case 200:
            Logger.network.debug("Response: \(String(data: data, encoding: .utf8)!)")
            return data
        default:
            let errorText = String(data: data, encoding: .utf8) ?? ""
            Logger.network.error("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            throw APIError.responseError(statusCode: httpResponse.statusCode, description: errorText)
        }
    }

    public struct EndPoint {
        let folder: String
        let models: [Model]
        
        public static let completions = Self(folder: "completions", models: [.text_davinci_003])
        public static let chats = Self(folder: "chat/completions", models: [.gpt_3_5_turbo, .gpt_4, .gpt_4_32k])
    }
    
    struct RequestBody: Encodable {
        let model: Model
        let maxTokens: Int?
        let temperature: Int?
        let stream: Bool
        let body: Codable
        
        enum CodingKeys: String, CodingKey {
            case model, maxTokens, temperature, stream
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model.id, forKey: .model)
            try container.encodeIfPresent(maxTokens, forKey: .maxTokens)
            try container.encodeIfPresent(temperature, forKey: .temperature)
            try container.encode(stream, forKey: .stream)
            try body.encode(to: encoder)
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
    
    enum APIError: LocalizedError {
        case invalidURLReponseType
        case responseError(statusCode: Int, description: String?)
    }

    // MARK: - Chats
    
    public func chat(_ text: String) async throws -> String {
        let message = Message(content: text)
        let data = try await call(endPoint: .chats, withBody: ChatBody(messages: history + [message]))
        let response = try JSONDecoder.api.decode(ChatResponse<ChatChoice>.self, from: data)
        
        guard let choice = response.choices.first else { throw ChatError.noChoices }
        guard let text = choice.message.content else { throw ChatError.noText(in: choice) }
        add(message: message)
        return text
    }
    
    public func chatStream(_ text: String) async throws -> ChatStreamResponse {
        let message = Message(content: text)
        return try await stream(endPoint: .chats, withBody: ChatBody(messages: history + [message]))
            .map({ try JSONDecoder.api.decode(ChatResponse<ChatDeltaChoice>.self, from: $0) })
            .compactMap({
                guard let choice = $0.choices.first else { return nil }
                guard let text = choice.delta.content else { return nil }
                self.add(message: message)
                return text
            })
    }
    
    // MARK: - Completion
    
    public func complete(_ prompt: String) async throws -> CompletionResponse {
        let data = try await call(endPoint: .completions, withBody: CompletionBody(prompt: prompt))
        return try JSONDecoder.api.decode(CompletionResponse.self, from: data)
    }
    
    public func completeStream(_ prompt: String) async throws -> AsyncThrowingMapSequence<StreamResponse, CompletionResponse> {
        try await stream(endPoint: .completions, withBody: CompletionBody(prompt: prompt))
            .map({ try JSONDecoder.api.decode(CompletionResponse.self, from: $0) })
    }
}
