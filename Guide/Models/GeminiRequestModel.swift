/*
 사물 인식 기능을 위한 Gemini- 2.5Flash 모델의 API요청 모델
*/

struct GeminiRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
    
    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String?
        let inlineData: InlineData?
    }

    struct InlineData: Encodable {
        let mimeType: String    // Ex) "image/jpeg"
        let data: String
    }

    struct GenerationConfig: Encodable {
        let temperature: Double?
        let thinkingConfig: ThinkingConfig?
    }

    struct ThinkingConfig: Encodable {
        let thinkingBudget: Int?
    }
}
