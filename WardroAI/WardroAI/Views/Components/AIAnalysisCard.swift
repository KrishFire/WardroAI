import SwiftUI

struct AIAnalysisCard: View {
    let isAnalyzing: Bool
    let suggestions: AISuggestedTags?
    let onAnalyze: () -> Void
    let onReanalyze: () -> Void
    let hasImage: Bool
    let onFeedback: ((Bool) -> Void)?
    
    init(isAnalyzing: Bool, suggestions: AISuggestedTags?, onAnalyze: @escaping () -> Void, onReanalyze: @escaping () -> Void, hasImage: Bool, onFeedback: ((Bool) -> Void)? = nil) {
        self.isAnalyzing = isAnalyzing
        self.suggestions = suggestions
        self.onAnalyze = onAnalyze
        self.onReanalyze = onReanalyze
        self.hasImage = hasImage
        self.onFeedback = onFeedback
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("AI Analysis")
                    .font(.headline)
                
                Spacer()
                
                if suggestions != nil {
                    Button("Re-analyze") {
                        onReanalyze()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Content based on state
            if isAnalyzing {
                HStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analyzing photo...")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Text("Identifying garment details with AI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            } else if let suggestions = suggestions {
                // AI Results
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("AI Analysis Complete")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    
                    // Suggestions summary
                    VStack(alignment: .leading, spacing: 4) {
                        if let category = suggestions.category {
                            HStack {
                                Text("Category:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(category.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        
                        if let colors = suggestions.colors, !colors.isEmpty {
                            HStack {
                                Text("Colors:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(suggestions.colorsDisplay)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        
                        if let brand = suggestions.brand {
                            HStack {
                                Text("Brand:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(brand)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                    }
                    
                    Text("Suggestions have been applied to the form")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                    
                    // User Feedback Section
                    if let onFeedback = onFeedback {
                        HStack(spacing: 8) {
                            Text("How did we do?")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button(action: { onFeedback(true) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "hand.thumbsup")
                                    Text("Good")
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                            }
                            
                            Button(action: { onFeedback(false) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "hand.thumbsdown")
                                    Text("Needs work")
                                }
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                            }
                            
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            } else {
                // No analysis yet
                VStack(spacing: 8) {
                    if hasImage {
                        Button(action: onAnalyze) {
                            HStack {
                                Image(systemName: "wand.and.rays")
                                Text("Analyze Photo with AI")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    } else {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                            Text("Add a photo to analyze with AI")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isAnalyzing ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

// Preview
struct AIAnalysisCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // No analysis state
            AIAnalysisCard(
                isAnalyzing: false,
                suggestions: nil,
                onAnalyze: {},
                onReanalyze: {},
                hasImage: false
            )
            
            // Ready to analyze
            AIAnalysisCard(
                isAnalyzing: false,
                suggestions: nil,
                onAnalyze: {},
                onReanalyze: {},
                hasImage: true
            )
            
            // Analyzing state
            AIAnalysisCard(
                isAnalyzing: true,
                suggestions: nil,
                onAnalyze: {},
                onReanalyze: {},
                hasImage: true
            )
            
            // Complete with suggestions
            AIAnalysisCard(
                isAnalyzing: false,
                suggestions: AISuggestedTags(
                    category: "shirt",
                    colors: ["blue", "white"],
                    brand: "Nike",
                    description: "Blue and white athletic shirt"
                ),
                onAnalyze: {},
                onReanalyze: {},
                hasImage: true
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
} 