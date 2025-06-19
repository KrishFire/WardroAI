import SwiftUI

struct ItemDetailView: View {
    let item: WardrobeItem
    @StateObject private var repository = WardrobeRepository()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Large image
                AsyncImageView(
                    url: item.photoUrl,
                    height: 300,
                    cornerRadius: 16
                )
                
                // Item details
                VStack(alignment: .leading, spacing: 16) {
                    // Title
                    Text(item.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Metadata grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DetailRow(title: "Category", value: item.category.capitalized)
                        DetailRow(title: "Brand", value: item.brand ?? "Not specified")
                        DetailRow(title: "Color", value: item.colorDisplay)
                        DetailRow(title: "Material", value: item.material?.capitalized ?? "Not specified")
                    }
                    
                    // Price if available
                    if let price = item.price {
                        DetailRow(title: "Price", value: String(format: "$%.2f", price))
                    }
                    
                    // Notes section
                    if let notes = item.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    
                    // Additional metadata
                    if let occasions = item.occasions, !occasions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Occasions")
                                .font(.headline)
                            
                            FlowLayout {
                                ForEach(occasions, id: \.self) { occasion in
                                    Text(occasion.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.purple.opacity(0.2))
                                        .foregroundColor(.purple)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                    
                    if let seasonality = item.seasonality, !seasonality.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seasonality")
                                .font(.headline)
                            
                            FlowLayout {
                                ForEach(seasonality, id: \.self) { season in
                                    Text(season.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit") {
                        showingEditView = true
                    }
                    Button("Delete", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditItemView(item: item)
        }
        .alert("Delete Item", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteItem()
            }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .overlay {
            if isLoading {
                ProgressView("Deleting item...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }
    
    private func deleteItem() {
        guard let itemId = item.id else { return }
        
        isLoading = true
        
        Task {
            do {
                try await repository.deleteItem(id: itemId)
                
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

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var height: CGFloat = 0
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        let spacing: CGFloat = 8
        
        for size in sizes {
            if currentWidth + size.width > (proposal.width ?? .infinity) && currentWidth > 0 {
                height += currentHeight + spacing
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentWidth += size.width + (currentWidth > 0 ? spacing : 0)
                currentHeight = max(currentHeight, size.height)
            }
        }
        
        height += currentHeight
        
        return CGSize(width: proposal.width ?? currentWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var x = bounds.minX
        var y = bounds.minY
        var currentRowHeight: CGFloat = 0
        let spacing: CGFloat = 8
        
        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]
            
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            
            x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}

#Preview {
    NavigationView {
        ItemDetailView(item: WardrobeItem(
            name: "Blue Nike Shirt",
            userId: UUID(),
            photoUrl: nil,
            category: "shirt",
            brand: "Nike",
            primaryColor: "blue",
            notes: "My favorite casual shirt"
        ))
    }
} 