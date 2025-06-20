import Foundation
import Supabase
import Functions

/// State of AI analysis operation
enum AIAnalysisState {
    case idle
    case analyzing
    case completed(AISuggestedTags)
    case failed(Error)
}

/// Errors that can occur during AI analysis
enum AIVisionError: LocalizedError {
    case invalidImageUrl
    case networkError
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidImageUrl:
            return "Invalid image URL"
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return "AI analysis failed: \(message)"
        case .parseError:
            return "Failed to parse AI response"
        }
    }
}

/// Service for AI-powered garment analysis
@MainActor
class AIVisionService: ObservableObject {
    private let supabase = SupabaseManager.shared.client
    
    @Published var analysisState: AIAnalysisState = .idle
    
    /// Analyzes a garment image using AI and returns suggested tags
    /// - Parameters:
    ///   - imageUrl: URL of the image stored in Supabase Storage
    ///   - userId: UUID of the user who owns the image
    /// - Returns: AI suggested tags for the garment
    func analyzeGarment(imageUrl: String, userId: UUID) async throws -> AISuggestedTags {
        analysisState = .analyzing
        
        do {
            // Validate image URL
            guard !imageUrl.isEmpty else {
                throw AIVisionError.invalidImageUrl
            }
            
            // Prepare request body
            let requestBody = [
                "imageUrl": imageUrl,
                "userId": userId.uuidString
            ]
            
            // Call Supabase Edge Function
            let response: AIAnalysisResponse = try await supabase.functions
                .invoke(
                    "analyze-garment",
                    options: FunctionInvokeOptions(
                        body: requestBody
                    )
                )
            
            // Check if the analysis was successful
            if response.success, let data = response.data {
                analysisState = .completed(data)
                return data
            } else {
                let errorMessage = response.error ?? "Unknown AI analysis error"
                let error = AIVisionError.apiError(errorMessage)
                analysisState = .failed(error)
                throw error
            }
            
        } catch {
            print("[AIVisionService] CAUGHT ERROR in analyzeGarment:")
            print("[AIVisionService] Error type: \(type(of: error))")
            print("[AIVisionService] Error description: \(error.localizedDescription)")
            print("[AIVisionService] Full error: \(error)")
            
            analysisState = .failed(error)
            
            // Convert Supabase errors to our error types
            if error is AIVisionError {
                print("[AIVisionService] Re-throwing AIVisionError")
                throw error
            } else if error.localizedDescription.contains("500") {
                print("[AIVisionService] Converting 500 error to apiError")
                throw AIVisionError.apiError("AI service is temporarily unavailable (HTTP 500). Please try again later.")
            } else if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                print("[AIVisionService] Converting to networkError")
                throw AIVisionError.networkError
            } else {
                print("[AIVisionService] Converting unknown error to apiError: \(error)")
                throw AIVisionError.apiError("AI analysis failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Resets the analysis state to idle
    func resetState() {
        analysisState = .idle
    }
    
    /// Returns true if analysis is currently in progress
    var isAnalyzing: Bool {
        if case .analyzing = analysisState {
            return true
        }
        return false
    }
    
    /// Returns the last analysis result if available
    var lastResult: AISuggestedTags? {
        if case .completed(let tags) = analysisState {
            return tags
        }
        return nil
    }
    
    /// Returns the last error if analysis failed
    var lastError: Error? {
        if case .failed(let error) = analysisState {
            return error
        }
        return nil
    }
} 