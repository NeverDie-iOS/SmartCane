/*
 사물 인식 기능을 위한 Gemini- 2.5Flash 모델의 API요청 모델
*/

import Foundation

// MARK: - 1
struct GeminiRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig?
}

// MARK: - 2
struct Content: Encodable {
    let parts: [Part]
}

// MARK: - 3
struct Part: Encodable {
    let text: String?
    let inlineData: InlineData?
}

// MARK: - 4
struct InlineData: Encodable {
    let mimeType: String    // Ex) "image/jpeg"
    let data: String
}

// MARK: - 5
struct GenerationConfig: Encodable {
    let temperature: Double?
    let thinkingConfig: ThinkingConfig?
}

// MARK: - 6
struct ThinkingConfig: Encodable {
    let thinkingBudget: Int?
}
