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
                height: nil,
                cornerRadius: 12
            )
            .aspectRatio(1, contentMode: .fill)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                // Quick action buttons overlay
                VStack {
                    HStack {
                        Spacer()
                        Menu {
                            Button("Delete", role: .destructive, action: onDelete)
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .background(
                                    Circle()
                                        .fill(.black.opacity(0.6))
                                        .frame(width: 26, height: 26)
                                )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .opacity(0.9)
                    }
                    Spacer()
                }
                .padding(10)
            )
            
            // Item details with proper spacing
            VStack(alignment: .leading, spacing: 8) {
                Text(item.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(item.category.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    Spacer()
                    
                    Text(item.colorDisplay)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                
                if let brand = item.brand {
                    Text(brand)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.separator, lineWidth: 0.5)
        )
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: item.id)
    }
}

struct CardPressedStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
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