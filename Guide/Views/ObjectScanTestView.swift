import SwiftUI
import PhotosUI
import UIKit
import AVFoundation

struct ObjectScanTestView: View {
    // MARK: -
    @State private var displayImage: Image?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedItemData: Data?
    
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    
    @State private var analysisResult: String = "분석 결과를 기다리는 중..."
    @State private var isLoading: Bool = false
    
    // MARK: -
    let geminiAPIService = GeminiAPIService()
    let speechSynthesizer = SpeechSynthesizer()
    
    // MARK: -
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    
                    if let displayImage {
                        displayImage
                            .resizable()
                            .scaledToFill()
                            .frame(width: 300, height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        VStack {
                            Image(systemName: "photo.stack.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("사진을 촬영/선택 해주세요.")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 15) {
                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("촬영하기")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("앨범 선택")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                Button(action: startAnalysis) {
                    Text(isLoading ? "분석 중..." : "사물/신호등 인식 요청")
                        .font(.headline)
                        .bold()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(isLoading || selectedItemData == nil)
                .padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("분석 결과")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        Text(analysisResult)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .multilineTextAlignment(.leading)
                            .padding(10)
                    }
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("AI 사물 인식")
        }
        
        // MARK: -
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(cameraImage: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedItem, perform: loadSelectedImage)
        .onChange(of: cameraImage, perform: updateCameraImage)
    }
    
    // MARK: -
    
    private func startAnalysis() {
        
        guard let data = selectedItemData else {
            self.analysisResult = "이미지가 존재하지 않습니다."
            speechSynthesizer.speak(text: "사진을 먼저 선택해 주세요.")
            return
        }
        
        isLoading = true
        self.analysisResult = "⏳ 분석 요청 중입니다."
        speechSynthesizer.speak(text: "분석 요청 중입니다.")
        
        Task {
            let result = await geminiAPIService.analyzeImage(data)
            self.analysisResult = result
            
            if result.starts(with: "ERROR") {
                speechSynthesizer.speak(text: "오류가 발생했습니다. \(result)")
            } else {
                speechSynthesizer.speak(text: result)
            }
            
            isLoading = false
        }
    }
    
    private func loadSelectedImage(newItem: PhotosPickerItem?) {
        Task {
            guard let newItem = newItem,
                  let data = try? await newItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            
            displayImage = Image(uiImage: uiImage)
            selectedItemData = uiImage.jpegData(compressionQuality: 0.5)
            self.analysisResult = "앨범 이미지 준비 완료"
        }
    }
    
    private func updateCameraImage(newImage: UIImage?) {
        guard let newImage = newImage else { return }
        selectedItemData = newImage.jpegData(compressionQuality: 0.5)
        self.displayImage = Image(uiImage: newImage)
        self.analysisResult = "카메라 이미지 준비 완료"
    }
}


// MARK: - 카메라 기능
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var cameraImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.cameraImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ObjectScanTestView()
}
