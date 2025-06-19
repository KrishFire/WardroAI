import Foundation
import Supabase

@MainActor
class WardrobeRepository: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Fetch Operations
    
    func fetchUserItems(userId: UUID) async throws -> [WardrobeItem] {
        let response: [WardrobeItem] = try await supabase
            .from("garment_items")
            .select()
            .eq("user_id", value: userId)
            .eq("is_archived", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Create Operations
    
    func addItem(_ item: WardrobeItem) async throws -> WardrobeItem {
        let response: WardrobeItem = try await supabase
            .from("garment_items")
            .insert(item)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Update Operations
    
    func updateItem(_ item: WardrobeItem) async throws -> WardrobeItem {
        guard let itemId = item.id else {
            throw WardrobeError.invalidItemId
        }
        
        let response: WardrobeItem = try await supabase
            .from("garment_items")
            .update(item)
            .eq("id", value: itemId)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Delete Operations
    
    func deleteItem(id: Int) async throws {
        try await supabase
            .from("garment_items")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    func archiveItem(id: Int) async throws -> WardrobeItem {
        let response: WardrobeItem = try await supabase
            .from("garment_items")
            .update(["is_archived": true])
            .eq("id", value: id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Image Upload
    
    func uploadImage(_ imageData: Data, fileName: String, userId: UUID) async throws -> String {
        // Use user-specific path for RLS security: userId/filename
        let path = "\(userId.uuidString)/\(UUID().uuidString)-\(fileName)"
        
        try await supabase.storage
            .from("wardrobe-images")
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        // Since bucket is now private, generate a signed URL for access
        let signedURL = try await supabase.storage
            .from("wardrobe-images")
            .createSignedURL(path: path, expiresIn: 31536000) // 1 year expiry
        
        return signedURL.absoluteString
    }
}

// MARK: - Error Types

enum WardrobeError: LocalizedError {
    case invalidItemId
    case uploadFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidItemId:
            return "Invalid item ID"
        case .uploadFailed:
            return "Failed to upload image"
        case .networkError:
            return "Network connection error"
        }
    }
} 