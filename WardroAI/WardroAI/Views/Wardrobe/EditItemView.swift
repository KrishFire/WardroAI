import SwiftUI

struct EditItemView: View {
    let item: WardrobeItem
    @Environment(\.dismiss) private var dismiss
    @StateObject private var repository = WardrobeRepository()
    @StateObject private var aiVisionService = AIVisionService()
    
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
    @State private var aiSuggestions: AISuggestedTags?
    @State private var uploadedImageUrl: String?
    
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
                LazyVStack(spacing: 24) {
                    // Photo section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Photo")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedImage != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.title3)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        
                        ZStack {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 250)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            } else {
                                AsyncImageView(
                                    url: item.photoUrl,
                                    height: 250,
                                    cornerRadius: 16
                                )
                            }
                        }
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        ImagePicker(selectedImage: $selectedImage, placeholder: "Change photo")
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .onChange(of: selectedImage) { _, newImage in
                                hasImageChanged = true
                                if newImage != nil {
                                    // Clear previous suggestions and reset error state
                                    aiSuggestions = nil
                                    showingError = false
                                    errorMessage = ""
                                }
                            }
                    }
                    .padding(.horizontal, 4)
                    
                    // AI Analysis section for re-analyzing existing items
                    AIAnalysisCard(
                        isAnalyzing: aiVisionService.isAnalyzing,
                        suggestions: aiSuggestions,
                        onAnalyze: analyzePhoto,
                        onReanalyze: analyzePhoto,
                        hasImage: selectedImage != nil || !(item.photoUrl ?? "").isEmpty,
                        onFeedback: { isPositive in
                            handleAIFeedback(isPositive: isPositive)
                        }
                    )
                    
                    // Metadata form
                    VStack(spacing: 20) {
                        // Item Name
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Item Name")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            TextField("Enter item name", text: $itemName)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                                .padding(.vertical, 2)
                        }
                        .padding(.horizontal, 4)
                        
                        // Category
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Category")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category.isEmpty ? "Select Category" : category)
                                        .tag(category)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accentColor(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Brand
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Brand")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            TextField("Enter brand name", text: $brand)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                                .padding(.vertical, 2)
                        }
                        .padding(.horizontal, 4)
                        
                        // Color
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Primary Color")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Picker("Color", selection: $primaryColor) {
                                ForEach(colors, id: \.self) { color in
                                    Text(color.isEmpty ? "Select Color" : color)
                                        .tag(color)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accentColor(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            TextField("Add any notes about this item", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                                .font(.body)
                                .padding(.vertical, 2)
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.body)
                    .fontWeight(.medium)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .disabled(isLoading || itemName.isEmpty || category.isEmpty)
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.white)
                            
                            Text("Saving changes...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func analyzePhoto() {
        print("[EditItemView] Starting analyzePhoto for item: \(item.name)")
        
        let imageToAnalyze: UIImage?
        let urlToUse: String
        
        if let selectedImage = selectedImage {
            // Use new selected image
            imageToAnalyze = selectedImage
            urlToUse = "" // Will be uploaded
            print("[EditItemView] Using new selected image for analysis")
        } else if let existingPhotoUrl = item.photoUrl, !existingPhotoUrl.isEmpty {
            // Use existing item photo URL
            imageToAnalyze = nil
            urlToUse = existingPhotoUrl
            print("[EditItemView] Using existing photo URL for analysis: \(existingPhotoUrl)")
        } else {
            // No image available for analysis
            print("[EditItemView] No image available for analysis")
            Task { @MainActor in
                errorMessage = "No image available for AI analysis. Please select a photo first."
                showingError = true
            }
            return
        }
        
        Task {
            do {
                print("[EditItemView] Entering 'do' block for AI analysis")
                var photoUrl = urlToUse
                
                // Upload new image if needed
                if let image = imageToAnalyze {
                    print("[EditItemView] Uploading new image...")
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        print("[EditItemView] THROWING: Failed to convert image to JPEG data")
                        throw WardrobeError.uploadFailed
                    }
                    
                    let fileName = "\(Date().timeIntervalSince1970)_temp.jpg"
                    photoUrl = try await repository.uploadImage(imageData, fileName: fileName, userId: item.userId)
                    print("[EditItemView] Image upload successful: \(photoUrl)")
                    
                    await MainActor.run {
                        uploadedImageUrl = photoUrl
                    }
                    print("[EditItemView] Stored uploadedImageUrl on MainActor")
                }
                
                // Analyze the image with AI
                print("[EditItemView] Starting AI vision analysis...")
                let suggestions = try await aiVisionService.analyzeGarment(imageUrl: photoUrl, userId: item.userId)
                print("[EditItemView] AI vision analysis successful: \(suggestions)")
                
                await MainActor.run {
                    aiSuggestions = suggestions
                    
                    // Apply suggestions with smart conflict detection
                    applyAISuggestionsToForm(suggestions)
                    print("[EditItemView] Applied AI suggestions to form successfully")
                }
                
                print("[EditItemView] AI Analysis SUCCEEDED, suggestions applied. About to exit 'do' block.")
                
            } catch {
                print("[EditItemView] analyzePhoto() CAUGHT an error: \(error)")
                print("[EditItemView] Error type: \(type(of: error))")
                print("[EditItemView] Error's localizedDescription: \(error.localizedDescription)")
                
                await MainActor.run {
                    // Enhanced error handling
                    let fallbackMessage = "AI analysis failed, but you can still edit your item manually."
                    
                    if error.localizedDescription.contains("network") || 
                       error.localizedDescription.contains("internet") {
                        errorMessage = "Network error: Please check your internet connection and try again. " + fallbackMessage
                    } else if error.localizedDescription.contains("upload") {
                        errorMessage = "Image upload failed. Please try selecting a different photo. " + fallbackMessage
                    } else {
                        errorMessage = "AI analysis encountered an issue: \(error.localizedDescription). " + fallbackMessage
                    }
                    
                    showingError = true
                    aiSuggestions = nil
                    print("[EditItemView] Set showingError = true and reset aiSuggestions")
                }
            }
        }
    }
     
     private func handleAIFeedback(isPositive: Bool) {
         // Simple feedback handling for MVP
         print("AI Feedback received in Edit mode: \(isPositive ? "Positive" : "Negative")")
         
         // Store feedback with AI suggestions for future reference
         if aiSuggestions != nil {
             let feedbackNote = isPositive ? "User liked AI re-analysis suggestions" : "User found AI re-analysis needs improvement"
             print("Edit Feedback: \(feedbackNote) for item: \(item.name)")
         }
     }
     
     private func applyAISuggestionsToForm(_ suggestions: AISuggestedTags) {
        // Smart mapping with conflict detection - more conservative for edit mode
        // Only apply if field appears to be default/placeholder value
        
        // Apply category suggestion if it's currently empty or "Select Category"
        if category.isEmpty || category == "Select Category", 
           let aiCategory = suggestions.category {
            let mappedCategory = mapAICategoryToForm(aiCategory)
            if categories.contains(mappedCategory) {
                category = mappedCategory
            }
        }
        
        // Apply color suggestion if it's currently empty
        if primaryColor.isEmpty, let aiColor = suggestions.primaryColor {
            let mappedColor = mapAIColorToForm(aiColor)
            if colors.contains(mappedColor) {
                primaryColor = mappedColor
            }
        }
        
        // Apply brand suggestion if it's currently empty
        if brand.isEmpty, let aiBrand = suggestions.brand {
            brand = aiBrand
        }
    }
    
    private func mapAICategoryToForm(_ aiCategory: String) -> String {
        let lowercased = aiCategory.lowercased()
        switch lowercased {
        case "shirt", "top", "blouse", "t-shirt", "tank":
            return "Top"
        case "pants", "jeans", "trousers", "shorts", "bottom":
            return "Bottom"
        case "dress":
            return "Dress"
        case "jacket", "coat", "blazer", "outerwear":
            return "Outerwear"
        case "shoes", "sneakers", "boots", "sandals":
            return "Shoes"
        case "accessories", "hat", "bag", "belt", "jewelry":
            return "Accessories"
        default:
            return ""
        }
    }
    
    private func mapAIColorToForm(_ aiColor: String) -> String {
        let lowercased = aiColor.lowercased()
        // Try to match common color names
        for formColor in colors {
            if formColor.lowercased() == lowercased {
                return formColor
            }
        }
        
        // Handle common variations
        switch lowercased {
        case "navy", "dark blue":
            return "Blue"
        case "light blue", "sky blue":
            return "Blue"
        case "dark red", "burgundy", "maroon":
            return "Red"
        case "light green", "lime":
            return "Green"
        case "dark green", "forest":
            return "Green"
        case "silver", "grey":
            return "Gray"
        case "beige", "tan", "khaki":
            return "Brown"
        default:
            return ""
        }
    }

    private func saveChanges() {
        isLoading = true
        
        Task {
            do {
                var photoUrl = item.photoUrl ?? ""
                
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
                    photoUrl: photoUrl.isEmpty ? nil : photoUrl,
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