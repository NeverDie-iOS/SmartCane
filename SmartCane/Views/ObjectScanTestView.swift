import SwiftUI
import PhotosUI

struct ObjectScanTestView: View {
    @State private var presentImage: Image?
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedItemData: Data?
    
    @State private var showCamera = false
    @State private var cameraImage: UIImage?
    
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
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePicker(cameraImage: $cameraImage)
                .ignoresSafeArea()
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedItemData = data
                    
                    if let uiImage = UIImage(data: data) {
                        presentImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
        .onChange(of: cameraImage) { newImage in
            guard let newImage else { return }
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
