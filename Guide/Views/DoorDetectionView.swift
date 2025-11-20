import AVFoundation
import SwiftUI
import Combine
import Vision
import CoreML

// MARK: - 데이터 모델 (DetectedDoor)

struct DetectedDoor: Identifiable {
    let id = UUID()
    let boundingBox: CGRect // 객체의 상대적 위치 (0.0 ~ 1.0)
    let confidence: Float   // 신뢰도 (0.0 ~ 1.0)
}

// MARK: - 카메라 및 Vision 관리자 (CameraManager)

class CameraManager: NSObject, ObservableObject {
    // --- 카메라 관련 변수 ---
    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // --- Vision & Core ML 관련 변수 ---
    private var visionRequests = [VNRequest]()
    
    // --- SwiftUI와 소통할 변수 ---
    @Published var isCameraRunning = false
    @Published var detectedDoors: [DetectedDoor] = []
    
    // --- 카메라 프레임 처리 핸들러 ---
    var frameProcessingHandler: ((CMSampleBuffer) -> Void)?

    override init() {
        super.init()
        
        // 카메라 프레임이 들어올 때마다 할 일 정의 (Vision에게 분석 요청)
        self.frameProcessingHandler = { [weak self] buffer in
            guard let self = self else { return }
            
            // 0.1초마다 한 번씩만 분석하도록 쓰로틀링 추가
            let now = Date()
            guard now.timeIntervalSince(self.lastAnalysisTime) >= 0.1 else { return }
            self.lastAnalysisTime = now

            // 들어온 영상 프레임(buffer)을 Vision이 처리할 수 있는 이미지 형태로 변환
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            
            // 분석 (별도 스레드에서 비동기로 실행)
            do {
                try imageRequestHandler.perform(self.visionRequests)
            } catch {
                print("Vision 요청 실패: \(error)")
            }
        }
        
        checkPermissions()
    }
    
    // 성능 개선용 변수 (쓰로틀링을 위한 마지막 분석 시간 기록)
    private var lastAnalysisTime = Date.distantPast

    // MARK: - 카메라 설정
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { DispatchQueue.main.async { self.setupCamera() } }
            }
        default:
            print("카메라 권한이 없습니다. 설정에서 허용해주세요.")
        }
    }

    private func setupCamera() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720 // 해상도 설정
        
        // 후면 광각 카메라 연결
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        if session.canAddInput(input) { session.addInput(input) }
        
        // 비디오 출력 연결 및 델리게이트 설정
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            //  메인 스레드가 아닌 별도 큐에서 프레임 처리 (버벅임 방지)
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue", qos: .userInitiated))
        }
        
        // 세로 모드 고정
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
             connection.videoOrientation = .portrait
        }
        
        session.commitConfiguration()
        
        setupVision() // Vision 준비
        
        // 카메라 시작 (백그라운드)
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
            DispatchQueue.main.async { self.isCameraRunning = self.session.isRunning }
        }
    }
    
    // MARK: - Vision & Core ML 설정 부분
    private func setupVision() {
        guard let model = try? VNCoreMLModel(for: doors().model) else {
            fatalError("Core ML 모델 로드 실패! 'doors().model' 이름을 확인하세요.")
        }

        let objectRecognition = VNCoreMLRequest(model: model) { [weak self] (request, error) in
            self?.handleDetectionResults(request: request, error: error)
        }
        
        objectRecognition.imageCropAndScaleOption = .scaleFit
        self.visionRequests = [objectRecognition]
    }

    private func handleDetectionResults(request: VNRequest, error: Error?) {
        if let error = error { print("Vision 에러: \(error.localizedDescription)"); return }
        guard let results = request.results as? [VNRecognizedObjectObservation] else { return }

        // 신뢰도 0.1(10%)만 인식
        let doors = results.filter { $0.confidence > 0.1 }
                           .map { DetectedDoor(boundingBox: $0.boundingBox, confidence: $0.confidence) }
        
        DispatchQueue.main.async {
            self.detectedDoors = doors
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        frameProcessingHandler?(sampleBuffer)
    }
}

// MARK: - 3. 카메라 화면 래퍼 (CameraPreview)

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: cameraManager.session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill // 화면 꽉 차게
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        //
    }
}

// MARK: - 메인 SwiftUI 뷰 (DoorDetectionView)

struct DoorDetectionView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            // 카메라 화면 (밑바탕)
            CameraPreview(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                ForEach(cameraManager.detectedDoors) { door in
                    // 좌표 변환 (Vision 좌표계 -> SwiftUI 좌표계)
                    let rect = CGRect(
                        x: door.boundingBox.minX * geometry.size.width,
                        y: (1 - door.boundingBox.maxY) * geometry.size.height,
                        width: door.boundingBox.width * geometry.size.width,
                        height: door.boundingBox.height * geometry.size.height
                    )
                    
                    // 박스 그리기
                    Rectangle()
                        .path(in: rect)
                        .stroke(Color.blue, lineWidth: 3.0)
                        
                    // 신뢰도 표시 텍스트
                    Text("\(Int(door.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.blue)
                        .cornerRadius(4)
                        .position(
                            x: rect.midX,
                            y: rect.minY - 15
                        )
                }
            }
        }
    }
}
