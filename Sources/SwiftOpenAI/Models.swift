import Foundation

extension SwiftOpenAI {
    
    public enum Model {
        case gpt_4
        case gpt_4_32k
        case gpt_3_5_turbo
        case text_davinci_003
        case custom(id: String)
        
        var id: String {
            switch self {
            case .gpt_4: return "gpt-4"
            case .gpt_4_32k: return "gpt-4-32k"
            case .gpt_3_5_turbo: return "gpt-3.5-turbo"
            case .text_davinci_003: return "text-davinci-003"
            case .custom(let id): return id
            }
        }
    }
}
