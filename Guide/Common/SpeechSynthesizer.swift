import AVFoundation

// MARK: 
class SpeechSynthesizer {
    
    private let synthesizer = AVSpeechSynthesizer()
    private let voice: AVSpeechSynthesisVoice?
    
    init() {
        self.voice = AVSpeechSynthesisVoice.speechVoices().first { $0.language == "ko-KR" }
        
        if self.voice == nil {
            print("TTS ERROR: 한국어 음성 폰트를 찾을 수 없습니다. 기본 음성을 사용합니다.")
        }
    }
    
    func speak(text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = self.voice
        utterance.rate = 0.55       // 말하는 속도
        utterance.volume = 1.0      // 볼륨
        
        synthesizer.speak(utterance)
    }
}
