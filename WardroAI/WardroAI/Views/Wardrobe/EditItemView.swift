import SwiftUI

struct EditItemView: View {
    let item: WardrobeItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var repository = WardrobeRepository()
    
    @State private var selectedImage: UIImage?
    @State private var itemName: String
    @State private var category: String
    @State private var brand: String
    @State private var primaryColor: String
    @State private var notes: String
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var hasImageChanged = false
    
    // Predefined options
    private let categories = ["", "Top", "Bottom", "Dress", "Outerwear", "Shoes", "Accessories", "Underwear"]
    private let colors = ["", "Black", "White", "Gray", "Brown", "Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink"]
    
    init(item: WardrobeItem) {
        self.item = item
        self._itemName = State(initialValue: item.name)
        self._category = State(initialValue: item.category.capitalized)
        self._brand = State(initialValue: item.brand ?? "")
        self._primaryColor = State(initialValue: item.primaryColor?.capitalized ?? "")
        self._notes = State(initialValue: item.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photo")
                            .font(.headline)
                        
                        ZStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(12)
                            } else {
                                AsyncImageView(
                                    url: item.photoUrl,
                                    height: 200,
                                    cornerRadius: 12
                                )
                            }
                            
                            // Change photo button
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    Button("Change Photo") {
                                        // Show image picker
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                                }
                            }
                            .padding(8)
                        }
                        
                        ImagePicker(selectedImage: $selectedImage, placeholder: "Change photo")
                            .onChange(of: selectedImage) { _, _ in
                                hasImageChanged = true
                            }
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
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(isLoading || itemName.isEmpty || category.isEmpty)
                }
            }
            .overlay {
                if isLoading {
                    ProgressView("Saving changes...")
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
    
    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                var photoUrl = item.photoUrl
                
                // Upload new image if changed
                if hasImageChanged, let image = selectedImage {
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        throw WardrobeError.uploadFailed
                    }
                    
                    let fileName = "\(Date().timeIntervalSince1970).jpg"
                    photoUrl = try await repository.uploadImage(imageData, fileName: fileName, userId: item.userId)
                }
                
                // Create updated item with existing ID and metadata
                let updatedItem = WardrobeItem(
                    id: item.id,
                    name: itemName,
                    userId: item.userId,
                    photoUrl: photoUrl,
                    photoThumbnailUrl: item.photoThumbnailUrl,
                    category: category.lowercased(),
                    subcategory: item.subcategory,
                    brand: brand.isEmpty ? nil : brand,
                    primaryColor: primaryColor.isEmpty ? nil : primaryColor.lowercased(),
                    material: item.material,
                    seasonality: item.seasonality,
                    occasions: item.occasions,
                    price: item.price,
                    notes: notes.isEmpty ? nil : notes,
                    aiIdentifiedTagsRaw: item.aiIdentifiedTagsRaw,
                    isArchived: item.isArchived,
                    createdAt: item.createdAt,
                    updatedAt: item.updatedAt
                )
                
                // Update in database
                _ = try await repository.updateItem(updatedItem)
                
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
    EditItemView(item: WardrobeItem(
        name: "Blue Nike Shirt",
        userId: UUID(),
        photoUrl: nil,
        category: "shirt",
        brand: "Nike",
        primaryColor: "blue",
        notes: "My favorite shirt"
    ))
} 