import SwiftUI

struct WardrobeItemCard: View {
    let item: WardrobeItem
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with fixed aspect ratio
            AsyncImageView(
                url: item.photoUrl,
                width: nil,
                height: 140,
                cornerRadius: 8
            )
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .overlay(
                // Quick action buttons overlay
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button("Delete", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.5))
                                        .frame(width: 24, height: 24)
                                )
                        }
                    }
                    Spacer()
                }
                .padding(8)
            )
            
            // Item details with proper spacing
            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(item.category.capitalized)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text(item.colorDisplay)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
}

#Preview {
    let sampleItem = WardrobeItem(
        name: "Blue Nike Shirt",
        userId: UUID(),
        photoUrl: nil,
        category: "shirt",
        brand: "Nike",
        primaryColor: "blue",
        notes: "Favorite t-shirt"
    )
    
    WardrobeItemCard(
        item: sampleItem,
        onDelete: {}
    )
    .padding()
} 