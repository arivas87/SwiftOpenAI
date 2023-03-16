import Foundation
import OSLog

/// This type lets you interect with GPT API by [OpenAI](https://openai.com) in a reliable but flexible way
public class SwiftOpenAI {
    
    public typealias StreamResponse = AsyncCompactMapSequence<AsyncLineSequence<URLSession.AsyncBytes>, Data>
    
    private let apiKey: String
    
    private let session = URLSession.shared
    private let baseUrl = URL(string: "https://api.openai.com/v1")!
    
    private static let name = "GPT"
    
    public var model: Model?
    public var temperature = 0
    public var maxTokens = 7
    
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
    
    private func request(to endPoint: EndPoint, withBody body: Codable, stream: Bool = false) throws -> URLRequest {
        let model = self.model ?? endPoint.models.first! // Use default model if not defined
        
        let requestBody = RequestBody(
            model: model, maxTokens: maxTokens, temperature: temperature, stream: stream,
            body: body)
        
        var request = URLRequest(url: baseUrl.appendingPathComponent(endPoint.folder, isDirectory: false))
        print("Request: \(request.url!)")
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try encoder.encode(requestBody)
        print("Body: \(String(data: request.httpBody!, encoding: .utf8)!)")
        Log.network.info("Body: \(String(data: request.httpBody!, encoding: .utf8)!)")
        
        return request
    }
    
    func stream(endPoint: EndPoint, withBody body: Codable) async throws -> StreamResponse {
        let request = try request(to: endPoint, withBody: body, stream: true)
        
        let (result, response) = try await session.bytes(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw GPTError.invalidURLReponseType }

        switch httpResponse.statusCode {
        case 200: return result.lines.compactMap({ line in
            print("Response: \(line)")
            Log.network.info("Response: \(line)")
            guard !line.contains("[DONE]") else { return nil }
            return line.hasPrefix("data: ") ? line.dropFirst(6).data(using: .utf8) : nil
        })
        default:
            var errorText = ""
            for try await line in result.lines {
                errorText += line
            }
            print("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            Log.network.error("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            throw GPTError.responseError(statusCode: httpResponse.statusCode, description: errorText)
        }
    }
    
    func call(endPoint: EndPoint, withBody body: Codable) async throws -> Data {
        let request = try request(to: endPoint, withBody: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw GPTError.invalidURLReponseType }

        switch httpResponse.statusCode {
        case 200:
            print("Response: \(String(data: data, encoding: .utf8)!)")
            Log.network.info("Response: \(String(data: data, encoding: .utf8)!)")
            return data
        default:
            let errorText = String(data: data, encoding: .utf8) ?? ""
            print("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            Log.network.error("Error code: \(httpResponse.statusCode), Error: \(errorText)")
            throw GPTError.responseError(statusCode: httpResponse.statusCode, description: errorText)
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
        let maxTokens: Int
        let temperature: Int
        let stream: Bool
        let body: Codable
        
        enum CodingKeys: String, CodingKey {
            case model, maxTokens, temperature, stream
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(model.id, forKey: .model)
            try container.encode(maxTokens, forKey: .maxTokens)
            try container.encode(temperature, forKey: .temperature)
            try container.encode(stream, forKey: .stream)
            try body.encode(to: encoder)
        }
    }
    
    struct Usage: Codable {
        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
    }
    
    enum GPTError: LocalizedError {
        case invalidURLReponseType
        case responseError(statusCode: Int, description: String?)
    }
    
    struct Log {
        static let network = Logger(subsystem: name, category: "network")
    }
    
    lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    lazy var encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}
