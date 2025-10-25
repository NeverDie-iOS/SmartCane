import SwiftUI
import PhotosUI

struct ObjectScanTestView: View {
    @State private var presentImage: Image? // 화면에 표시할 이미지
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedItemData: Data? // JPEG Data
    
    @State private var showCamera = false // 카메라 시트 On/Off
    @State private var cameraImage: UIImage? // 카메라로 촬영한 이미지
    
    var body: some View {
        VStack {
            if let presentImage {
                presentImage
                    .resizable()
                    .frame(width: 300, height: 300)
            } else {
                Rectangle()
                    .foregroundStyle(Color.clear)
                    .frame(width: 300, height: 300)
            }
            
            HStack {
                Button {
                    showCamera = true
                } label: {
                    Text("사진 촬영하기")
                }
                
                PhotosPicker("앨범에서 선택", selection: $selectedItem, matching: .images)
            }
            
            Button {
                if let selectedItemData {
                    let base64IncodedString: String = selectedItemData.base64EncodedString()
                } else {
                    print("선택된 사진의 데이터가 없습니다.")
                }
            } label: {
                Text("Chat gpt 요청")
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(cameraImage: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        presentImage = Image(uiImage: uiImage)
                        selectedItemData = uiImage.jpegData(compressionQuality: 0.8)
                    }
                }
            }
        }
        .onChange(of: cameraImage) { newImage in
            guard let newImage else { return }
            selectedItemData = newImage.jpegData(compressionQuality: 0.8)
            self.presentImage = Image(uiImage: newImage)
        }
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
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
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
