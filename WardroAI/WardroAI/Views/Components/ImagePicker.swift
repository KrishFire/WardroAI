import SwiftUI
import PhotosUI

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingActionSheet = false
    @State private var photosPickerItem: PhotosPickerItem?
    
    let placeholder: String
    
    init(selectedImage: Binding<UIImage?>, placeholder: String = "Add Photo") {
        self._selectedImage = selectedImage
        self.placeholder = placeholder
    }
    
    var body: some View {
        Button(action: {
            showingActionSheet = true
        }) {
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            VStack {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                Text(placeholder)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
        }
        .confirmationDialog("Select Photo", isPresented: $showingActionSheet) {
            Button("Camera") {
                showingCamera = true
            }
            Button("Photo Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage)
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                    }
                }
            }
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
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
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ImagePicker(selectedImage: .constant(nil))
} 