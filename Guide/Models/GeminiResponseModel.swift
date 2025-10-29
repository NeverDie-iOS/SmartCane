/*
 사물 인식 기능을 위한 Gemini- 2.5Flash 모델의 API응답 모델
*/

struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    let usageMetadata: UsageMetadata?
    
    struct Candidate: Decodable {
        let content: Content?
        let finishReason: String?
        let index: Int?
    }
    
    struct Content: Decodable {
        let role: String?
        let parts: [Part]?
    }
    
    struct Part: Decodable {
        let text: String?
    }
    
    struct UsageMetadata: Decodable {
        let promptTokenCount: Int?
        let candidatesTokenCount: Int?
        let totalTokenCount: Int?
    }
}
