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
        
        print("[WardrobeRepository] Starting image upload...")
        print("[WardrobeRepository] Path: \(path)")
        print("[WardrobeRepository] Image data size: \(imageData.count) bytes")
        print("[WardrobeRepository] User ID: \(userId.uuidString)")
        print("[WardrobeRepository] File name: \(fileName)")
        
        do {
            try await supabase.storage
                .from("wardrobe-images")
                .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
            
            print("[WardrobeRepository] Image upload successful, generating signed URL...")
            
            // Since bucket is now private, generate a signed URL for access
            let signedURL = try await supabase.storage
                .from("wardrobe-images")
                .createSignedURL(path: path, expiresIn: 31536000) // 1 year expiry
            
            print("[WardrobeRepository] Signed URL generated: \(signedURL.absoluteString)")
            return signedURL.absoluteString
            
        } catch {
            print("[WardrobeRepository] Upload failed with error: \(error)")
            print("[WardrobeRepository] Error type: \(type(of: error))")
            print("[WardrobeRepository] Error description: \(error.localizedDescription)")
            
            // Re-throw with more specific error handling
            if error.localizedDescription.contains("SSL") || 
               error.localizedDescription.contains("network") ||
               error.localizedDescription.contains("connection") {
                throw WardrobeError.networkError
            } else {
                throw WardrobeError.uploadFailed
            }
        }
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