import Foundation

/// Represents AI-suggested tags for a clothing item
struct AISuggestedTags: Codable {
    let category: String?
    let colors: [String]?
    let brand: String?
    let description: String?
    
    /// Creates AI suggested tags with optional properties
    init(category: String? = nil, colors: [String]? = nil, brand: String? = nil, description: String? = nil) {
        self.category = category
        self.colors = colors
        self.brand = brand
        self.description = description
    }
    
    /// Returns true if both category and colors are available
    var isComplete: Bool {
        return category != nil && colors != nil && !colors!.isEmpty
    }
    
    /// Primary color for UI display (first color in the array)
    var primaryColor: String? {
        return colors?.first
    }
    
    /// Formatted colors string for display
    var colorsDisplay: String {
        guard let colors = colors, !colors.isEmpty else {
            return "Unknown"
        }
        return colors.map { $0.capitalized }.joined(separator: ", ")
    }
}

/// Response structure from AI analysis Edge Function
struct AIAnalysisResponse: Codable {
    let success: Bool
    let data: AISuggestedTags?
    let error: String?
} 