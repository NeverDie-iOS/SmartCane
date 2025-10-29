/*
 Model - Gemini 2.5 Flash
 Created - 10/25 2025
 
 스마트 지팡이 사물 인식을 위한 서비스
 - 신호등 인식 (우선순위)
 - 사물 스캔 후 사용자에게 알림
 */

import Foundation
import Alamofire

// MARK: -
class GeminiAPIService {
    private let apiKey: String?
    private let modelName: String = "gemini-2.5-flash"
    
    init() {
        self.apiKey = Bundle.main.infoDictionary?["GeminiAPIKey"] as? String
        
        if self.apiKey == nil || self.apiKey?.isEmpty == true {
            print("ERROR: Gemini API Key (GeminiAPIKey)가 Info.plist에 설정되지 않았습니다.")
        }
    }

    private var apiURL: URL? {
        guard let key = apiKey else { return nil }
        return URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(key)")
    }
    
    
    // MARK: -
    func analyzeImage(_ imageData: Data?) async -> String {
        print("이미지 분석 시작")
        
        guard let apiURL = self.apiURL else {
            return "ERROR: API Key가 설정되지 않았거나 URL 구성에 실패했습니다."
        }
        
        print("api URL = \(apiURL)")
        
        let base64Image = imageData!.base64EncodedString()
        let mimeType = "image/jpeg"
        
        // 2. 요청 본문(GeminiRequest) 생성
        let prompt = (Bundle.main.infoDictionary?["Prompt"] as? String)!
        
        let requestBody = self.createAnalysisRequest(
            prompt: prompt,
            base64Image: base64Image,
            mimeType: mimeType
        )
        
        guard let (data, response) = await self.performAPIRequest(with: requestBody, url: apiURL) else {
            return "ERROR: API 요청 실행 중 알 수 없는 오류가 발생했습니다."
        }
        
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            let errorBody = String(data: data, encoding: .utf8) ?? "본문 없음"
            print("DEBUG: API 호출 실패. 상태 코드: \(httpResponse.statusCode). 응답: \(errorBody)")
            return "ERROR: API 호출 실패 (상태 코드 \(httpResponse.statusCode))"
        }
        
        return self.processTextResponseData(data)
    }
    
    // MARK: - 요청 본문
    private func createAnalysisRequest(prompt: String, base64Image: String, mimeType: String) -> GeminiRequest {
        
        let imagePart = GeminiRequest.Part(text: nil, inlineData: GeminiRequest.InlineData(mimeType: mimeType, data: base64Image))
        let textPart = GeminiRequest.Part(text: prompt, inlineData: nil)
        
        let contents = [
            GeminiRequest.Content(parts: [imagePart, textPart])
        ]

        let thinkingConfig = GeminiRequest.ThinkingConfig(thinkingBudget: 0)
        
        let config = GeminiRequest.GenerationConfig(
            temperature: 0.0,
            thinkingConfig: thinkingConfig
        )
        
        return GeminiRequest(contents: contents, generationConfig: config)
    }
    
    // MARK: -
    private func performAPIRequest(with requestBody: GeminiRequest, url: URL) async -> (Data, URLResponse)? {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        guard let httpBody = try? encoder.encode(requestBody) else {
            print("DEBUG: 요청 본문 인코딩 실패.")
            return nil
        }
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return (data, response)
        } catch {
            print("DEBUG: URLSession 데이터 요청 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: -
    private func processTextResponseData(_ data: Data) -> String {
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let geminiResponse = try? decoder.decode(GeminiResponse.self, from: data) else {
            let rawString = String(data: data, encoding: .utf8) ?? "바이너리 데이터"
            print("DEBUG: GeminiResponse 디코딩 실패. 원본 응답:\n\(rawString)")
            return "ERROR: API 응답을 디코딩할 수 없습니다."
        }
        
        guard let textResponse = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            print("DEBUG: 응답 구조에서 텍스트를 찾을 수 없습니다.")
            return "ERROR: 응답에서 텍스트를 찾을 수 없거나 모델 생성에 실패했습니다."
        }
        print(textResponse)
        
        return textResponse
    }
}
