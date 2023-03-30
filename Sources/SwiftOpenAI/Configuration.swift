import Foundation

extension SwiftOpenAI {
    
    public struct Configuration {
        public var model: Model?
        public var temperature: Int?
        public var maxTokens: Int?
        
        public static let standard = Configuration()
    }
}
