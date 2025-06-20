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
            LazyVStack(alignment: .leading, spacing: 24) {
                // Large image
                AsyncImageView(
                    url: item.photoUrl,
                    height: 350,
                    cornerRadius: 20
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                // Item details
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text(item.displayName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Metadata grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        DetailRow(title: "Category", value: item.category.capitalized)
                        DetailRow(title: "Brand", value: item.brand ?? "Not specified")
                        DetailRow(title: "Color", value: item.colorDisplay)
                        DetailRow(title: "Material", value: item.material?.capitalized ?? "Not specified")
                    }
                    .padding(.horizontal, 4)
                    
                    // Price if available
                    if let price = item.price {
                        DetailRow(title: "Price", value: String(format: "$%.2f", price))
                            .padding(.horizontal, 4)
                    }
                    
                    // Notes section
                    if let notes = item.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text(notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .lineLimit(nil)
                                .padding(16)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(.separator, lineWidth: 0.5)
                                )
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    // Additional metadata
                    if let occasions = item.occasions, !occasions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Occasions")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            FlowLayout {
                                ForEach(occasions, id: \.self) { occasion in
                                    Text(occasion.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.purple.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.purple)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.purple.opacity(0.3), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    if let seasonality = item.seasonality, !seasonality.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Seasonality")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            FlowLayout {
                                ForEach(seasonality, id: \.self) { season in
                                    Text(season.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                                        .foregroundStyle(.green)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.regularMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                        
                        Text("Deleting item...")
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.separator, lineWidth: 0.5)
        )
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