import SwiftUI

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var repository = WardrobeRepository()
    @StateObject private var aiVisionService = AIVisionService()
    
    @State private var selectedImage: UIImage?
    @State private var itemName = ""
    @State private var category = ""
    @State private var brand = ""
    @State private var primaryColor = ""
    @State private var notes = ""
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingAIAnalysis = false
    @State private var aiSuggestions: AISuggestedTags?
    @State private var uploadedImageUrl: String?
    
    let userId: UUID
    
    // Predefined categories for picker
    private let categories = ["", "Top", "Bottom", "Dress", "Outerwear", "Shoes", "Accessories", "Underwear"]
    private let colors = ["", "Black", "White", "Gray", "Brown", "Red", "Blue", "Green", "Yellow", "Orange", "Purple", "Pink"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Photo selection section
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
                        
                        ImagePicker(
                            selectedImage: $selectedImage,
                            placeholder: "Add a photo of your item"
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 4)
                    
                    // AI Analysis section
                    AIAnalysisCard(
                        isAnalyzing: aiVisionService.isAnalyzing,
                        suggestions: aiSuggestions,
                        onAnalyze: analyzePhoto,
                        onReanalyze: analyzePhoto,
                        hasImage: selectedImage != nil,
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
            .navigationTitle("Add Item")
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
                        saveItem()
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .disabled(isLoading || selectedImage == nil || itemName.isEmpty || category.isEmpty)
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
                            
                            Text("Saving item...")
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
            .onChange(of: selectedImage) { oldImage, newImage in
                print("[AddItemView] selectedImage changed - oldImage: \(oldImage != nil ? "exists" : "nil"), newImage: \(newImage != nil ? "exists" : "nil")")
                
                // Automatically trigger AI analysis when image is selected
                if newImage != nil && oldImage != newImage {
                    print("[AddItemView] New image selected, preparing for auto-analysis")
                    
                    // Clear previous suggestions and reset error state
                    aiSuggestions = nil
                    showingError = false
                    errorMessage = ""
                    
                    // Auto-trigger analysis after a brief delay to ensure UI updates
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("[AddItemView] Auto-triggering AI analysis after delay")
                        analyzePhoto()
                    }
                }
            }
        }
    }
    
    private func analyzePhoto() {
        guard let image = selectedImage else { 
            print("[AddItemView] analyzePhoto() called but selectedImage is nil")
            return 
        }
        
        print("[AddItemView] Starting AI analysis for selected image")
        
        Task {
            do {
                print("[AddItemView] Entering 'do' block for AI analysis")
                
                // First upload the image to get a URL for AI analysis
                guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                    print("[AddItemView] THROWING: Failed to convert image to JPEG data")
                    throw WardrobeError.uploadFailed
                }
                
                print("[AddItemView] Image data conversion successful, uploading image...")
                let fileName = "\(Date().timeIntervalSince1970)_temp.jpg"
                let photoUrl = try await repository.uploadImage(imageData, fileName: fileName, userId: userId)
                print("[AddItemView] Image upload successful: \(photoUrl)")
                
                // Store the URL for later use in saveItem()
                await MainActor.run {
                    uploadedImageUrl = photoUrl
                }
                print("[AddItemView] Stored uploadedImageUrl on MainActor")
                
                // Analyze the image with AI
                print("[AddItemView] Starting AI vision analysis...")
                let suggestions = try await aiVisionService.analyzeGarment(imageUrl: photoUrl, userId: userId)
                print("[AddItemView] AI vision analysis successful: \(suggestions)")
                
                await MainActor.run {
                    aiSuggestions = suggestions
                    
                    // Smart mapping with conflict detection
                    applyAISuggestionsToForm(suggestions)
                    print("[AddItemView] Applied AI suggestions to form successfully")
                }
                
                print("[AddItemView] AI Analysis SUCCEEDED, suggestions applied. About to exit 'do' block.")
                
            } catch {
                print("[AddItemView] analyzePhoto() CAUGHT an error: \(error)")
                print("[AddItemView] Error type: \(type(of: error))")
                print("[AddItemView] Error's localizedDescription: \(error.localizedDescription)")
                
                await MainActor.run {
                    // Enhanced error handling with fallback
                    let fallbackMessage = "AI analysis failed, but you can still add your item manually. " +
                                         "Please fill in the details yourself."
                    
                    if error.localizedDescription.contains("network") || 
                       error.localizedDescription.contains("internet") {
                        errorMessage = "Network error: Please check your internet connection and try again. " + fallbackMessage
                    } else if error.localizedDescription.contains("upload") {
                        errorMessage = "Image upload failed. Please try selecting a different photo. " + fallbackMessage
                    } else {
                        errorMessage = "AI analysis encountered an issue: \(error.localizedDescription). " + fallbackMessage
                    }
                    
                    showingError = true
                    
                    // Ensure AI analysis state is reset even on error
                    aiSuggestions = nil
                    print("[AddItemView] Set showingError = true and reset aiSuggestions")
                }
            }
        }
    }
    
    private func applyAISuggestionsToForm(_ suggestions: AISuggestedTags) {
        // Smart mapping with conflict detection - only apply if user hasn't filled the field
        
        // Apply category suggestion if category field is empty
        if category.isEmpty, let aiCategory = suggestions.category {
            let mappedCategory = mapAICategoryToForm(aiCategory)
            if categories.contains(mappedCategory) {
                category = mappedCategory
            }
        }
        
        // Apply color suggestion if color field is empty
        if primaryColor.isEmpty, let aiColor = suggestions.primaryColor {
            let mappedColor = mapAIColorToForm(aiColor)
            if colors.contains(mappedColor) {
                primaryColor = mappedColor
            }
        }
        
        // Apply brand suggestion if brand field is empty
        if brand.isEmpty, let aiBrand = suggestions.brand {
            brand = aiBrand
        }
        
        // Apply item name suggestion if name field is empty and we have a description
        if itemName.isEmpty, let description = suggestions.description {
            // Generate a simple name from the description
            let words = description.split(separator: " ").prefix(3)
            let suggestedName = words.map { $0.capitalized }.joined(separator: " ")
            if !suggestedName.isEmpty {
                itemName = suggestedName
            }
        }
    }
    
    private func handleAIFeedback(isPositive: Bool) {
        // Simple feedback handling for MVP
        // In the future, this could log to analytics or improve AI model training
        print("AI Feedback received: \(isPositive ? "Positive" : "Negative")")
        
        // Store feedback with AI suggestions for future reference
        if let suggestions = aiSuggestions {
            // This could be enhanced to store feedback in the database
            let feedbackNote = isPositive ? "User liked AI suggestions" : "User found AI suggestions needs improvement"
            print("Feedback: \(feedbackNote) for suggestions: \(suggestions)")
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
    
    private func saveItem() {
        guard let image = selectedImage else { return }
        
        isLoading = true
        
        Task {
            do {
                var photoUrl: String
                
                // Use already uploaded image URL if available (from AI analysis)
                if let existingUrl = uploadedImageUrl {
                    photoUrl = existingUrl
                } else {
                    // Upload image if not already uploaded
                    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                        throw WardrobeError.uploadFailed
                    }
                    
                    let fileName = "\(Date().timeIntervalSince1970).jpg"
                    photoUrl = try await repository.uploadImage(imageData, fileName: fileName, userId: userId)
                }
                
                // Prepare AI suggestions data for storage
                var aiIdentifiedTagsRaw: String?
                if let suggestions = aiSuggestions {
                    let aiData = [
                        "category": suggestions.category ?? "",
                        "colors": suggestions.colors ?? [],
                        "source": "gpt4o",
                        "timestamp": ISO8601DateFormatter().string(from: Date())
                    ] as [String: Any]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: aiData),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        aiIdentifiedTagsRaw = jsonString
                    }
                }
                
                // Create wardrobe item with AI tags included
                let itemToSave = WardrobeItem(
                    name: itemName,
                    userId: userId,
                    photoUrl: photoUrl,
                    category: category.lowercased(),
                    brand: brand.isEmpty ? nil : brand,
                    primaryColor: primaryColor.isEmpty ? nil : primaryColor.lowercased(),
                    notes: notes.isEmpty ? nil : notes,
                    aiIdentifiedTagsRaw: aiIdentifiedTagsRaw
                )
                
                // Save to database
                _ = try await repository.addItem(itemToSave)
                
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