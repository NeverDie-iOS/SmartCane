import Foundation
import SwiftUI
import Alamofire
import AVFoundation
import Combine

class CaneViewModel: ObservableObject {
    @Published var displayImage: Image?
    @Published var isLoading: Bool = false
    @Published var showFlash: Bool = false
    
    // 연결 상태
    @Published var pollingStatus: String = "🔴 연결 대기"
    
    // 결과 텍스트
    @Published var statusMessage: String = ""
    
    // 내부 로직용
    @Published var isConnected: Bool = false
    
    // ----------------------------------------
    // 서비스 및 설정
    // ----------------------------------------
    private let geminiAPIService = GeminiAPIService()
    private let speechSynthesizer = SpeechSynthesizer()
    private let caneBaseURL = "http://192.168.4.1"
    
    private var pollingTimer: Timer?
    
    // ----------------------------------------
    // 세션 설정
    // ----------------------------------------
    private let pollingSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 1
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
    
    private let captureSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()

    // ============================================================
    // MARK: - 폴링 (버튼 감지)
    // ============================================================
    
    func startPolling() {
        print("버튼 감시 시작")
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkButtonStatus()
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    private func checkButtonStatus() {
        if isLoading { return }
        
        guard let url = URL(string: "\(caneBaseURL)/status") else { return }
        
        pollingSession.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let _ = error {
                DispatchQueue.main.async { self.pollingStatus = "🔴 끊김"; self.isConnected = false }
                return
            }
            
            DispatchQueue.main.async {
                if !self.isConnected { self.isConnected = true }
                if self.pollingStatus != "🟢 연결됨" { self.pollingStatus = "🟢 연결됨" }
            }
            
            if let data = data, let text = String(data: data, encoding: .utf8) {
                if text.trimmingCharacters(in: .whitespacesAndNewlines) == "1" {
                    print("🔘 지팡이 버튼 눌림 확인!")
                    self.triggerCaptureAction()
                }
            }
        }.resume()
    }
    
    // ============================================================
    // MARK: - 캡처 및 분석 액션
    // ============================================================
    
    private func triggerCaptureAction() {
        DispatchQueue.main.async {
            withAnimation(.easeIn(duration: 0.1)) { self.showFlash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) { self.showFlash = false }
            }
            
            withAnimation { self.statusMessage = "AI가 이미지를 분석하고 있습니다..." }
        }
        
        Task { await self.fetchPhotoFromCane() }
    }

    @MainActor
    func fetchPhotoFromCane() async {
        isLoading = true
        
        guard let url = URL(string: "\(caneBaseURL)/capture?t=\(Date().timeIntervalSince1970)") else { return }
        
        do {
            let (data, _) = try await captureSession.data(from: url)
            
            if let uiImage = UIImage(data: data) {
                self.displayImage = Image(uiImage: uiImage)
                
                let resultText = await geminiAPIService.analyzeImage(data)
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.statusMessage = resultText
                }
                
                speechSynthesizer.speak(text: resultText)
                print("분석 결과: \(resultText)")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.displayImage = nil
                        self.statusMessage = ""
                    }
                }
                
            } else {
                self.statusMessage = "사진 변환 실패"
                speechSynthesizer.speak(text: "오류가 발생했습니다.")
            }
        } catch {
            print("통신 실패: \(error.localizedDescription)")
            self.statusMessage = "지팡이 연결 확인 필요"
            speechSynthesizer.speak(text: "연결 실패")
        }
        
        isLoading = false
    }
}
