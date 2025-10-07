import SwiftUI
import PhotosUI

struct ObjectScanTestView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedItemData: Data?
    @State private var selectedImage: Image?
    
    
    var body: some View {
        VStack {
            if let selectedImage {
                selectedImage
                    .resizable()
                    .frame(width: 300, height: 300)
            } else {
                Rectangle()
                    .foregroundStyle(Color.clear)
                    .frame(width: 300, height: 300)
            }
            
            HStack {
                Button {
                    
                } label: {
                    Text("사진 촬영하기")
                }
                
                PhotosPicker("앨범에서 선택", selection: $selectedItem, matching: .images)
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedItemData = data
            
                    if let uiImage = UIImage(data: data) {
                        selectedImage = Image(uiImage: uiImage)
                    }
                }
            }
        }
    }
}

#Preview {
    ObjectScanTestView()
}
