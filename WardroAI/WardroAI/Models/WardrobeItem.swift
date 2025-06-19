import Foundation

struct WardrobeItem: Identifiable, Codable {
    let id: Int?
    let userId: UUID
    let name: String
    let photoUrl: String?
    let photoThumbnailUrl: String?
    let category: String
    let subcategory: String?
    let brand: String?
    let primaryColor: String?
    let material: String?
    let seasonality: [String]?
    let occasions: [String]?
    let price: Double?
    let notes: String?
    let aiIdentifiedTagsRaw: String? // JSON string instead of [String: Any]
    let isArchived: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    // Coding keys to match Supabase column names
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case photoUrl = "image_url"
        case photoThumbnailUrl = "photo_thumbnail_url"
        case category
        case subcategory
        case brand
        case primaryColor = "primary_color"
        case material
        case seasonality
        case occasions
        case price
        case notes
        case aiIdentifiedTagsRaw = "ai_identified_tags_raw"
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Convenience initializer for new items
    init(name: String, userId: UUID, photoUrl: String? = nil, category: String, brand: String? = nil, primaryColor: String? = nil, notes: String? = nil) {
        self.id = nil
        self.name = name
        self.userId = userId
        self.photoUrl = photoUrl
        self.photoThumbnailUrl = nil
        self.category = category
        self.subcategory = nil
        self.brand = brand
        self.primaryColor = primaryColor
        self.material = nil
        self.seasonality = nil
        self.occasions = nil
        self.price = nil
        self.notes = notes
        self.aiIdentifiedTagsRaw = nil
        self.isArchived = false
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    // Complete initializer for updates
    init(id: Int?, name: String, userId: UUID, photoUrl: String?, photoThumbnailUrl: String?, category: String, subcategory: String?, brand: String?, primaryColor: String?, material: String?, seasonality: [String]?, occasions: [String]?, price: Double?, notes: String?, aiIdentifiedTagsRaw: String?, isArchived: Bool, createdAt: Date?, updatedAt: Date?) {
        self.id = id
        self.name = name
        self.userId = userId
        self.photoUrl = photoUrl
        self.photoThumbnailUrl = photoThumbnailUrl
        self.category = category
        self.subcategory = subcategory
        self.brand = brand
        self.primaryColor = primaryColor
        self.material = material
        self.seasonality = seasonality
        self.occasions = occasions
        self.price = price
        self.notes = notes
        self.aiIdentifiedTagsRaw = aiIdentifiedTagsRaw
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Helper extensions
extension WardrobeItem {
    var displayName: String {
        if !name.isEmpty {
            return name
        } else if let brand = brand {
            return "\(brand) \(category)"
        } else {
            return category.capitalized
        }
    }
    
    var colorDisplay: String {
        primaryColor?.capitalized ?? "Unknown"
    }
} 