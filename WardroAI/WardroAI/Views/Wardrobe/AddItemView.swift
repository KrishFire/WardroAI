import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var repository = WardrobeRepository()
    
    @State private var selectedImage: UIImage?
    @State private var itemName = ""
    @State private var category = ""
    @State private var brand = ""
    @State private var primaryColor = ""
    @State private var notes = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let userId: UUID
    
    // Predefined categories for picker
    private let categories = ["", "Top", "Bottom", "Dress", "Outerwear", "Shoes", "Accessories", "Underwear"]
    private let colors = ["", "Black", "White", "Gray", "Brown", "Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo selection section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        ImagePicker(
                            selectedImage: $selectedImage,
                            placeholder: "Add a photo of your item"
                        )
                    }
                    
                    // Metadata form
                    VStack(spacing: 16) {
                        // Item Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Item Name")
                                .font(.headline)
                            
                            TextField("Enter item name", text: $itemName)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category.isEmpty ? "Select Category" : category)
                                        .tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Brand
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Brand")
                                .font(.headline)
                            
                            TextField("Enter brand name", text: $brand)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Primary Color")
                                .font(.headline)
                            
                            Picker("Color", selection: $primaryColor) {
                                ForEach(colors, id: \.self) { color in
                                    Text(color.isEmpty ? "Select Color" : color)
                                        .tag(color)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            TextField("Add any notes about this item", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(isLoading || selectedImage == nil || itemName.isEmpty || category.isEmpty)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving item...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveItem() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                // Convert image to data
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    throw WardrobeError.uploadFailed
                }
                
                // Upload image
                let fileName = "\(Date().timeIntervalSince1970).jpg"
                let photoUrl = try await repository.uploadImage(imageData, fileName: fileName, userId: userId)
                
                // Create wardrobe item
                let newItem = WardrobeItem(
                    name: itemName,
                    userId: userId,
                    photoUrl: photoUrl,
                    category: category.lowercased(),
                    brand: brand.isEmpty ? nil : brand,
                    primaryColor: primaryColor.isEmpty ? nil : primaryColor.lowercased(),
                    notes: notes.isEmpty ? nil : notes
                )
                
                // Save to database
                _ = try await repository.addItem(newItem)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    AddItemView(userId: UUID())
} 