import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: WardrobeViewModel
    
    // Grid layout following Apple's design guidelines
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    init() {
        // Initialize with a temporary UUID - will be replaced in onAppear
        self._viewModel = StateObject(wrappedValue: WardrobeViewModel(userId: UUID()))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading wardrobe...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isEmpty {
                    emptyStateView
                } else {
                    wardrobeGridView
                }
            }
            .navigationTitle("Wardrobe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshItems()
            }
            .sheet(isPresented: $viewModel.showingAddItem, onDismiss: {
                viewModel.loadItems()
            }) {
                AddItemView(userId: viewModel.userId)
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    viewModel.updateUserId(userId)
                    viewModel.loadItems()
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your wardrobe is empty")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start building your digital wardrobe by adding your first item")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Add First Item") {
                viewModel.showingAddItem = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var wardrobeGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        WardrobeItemCard(
                            item: item,
                            onDelete: {
                                viewModel.deleteItem(item)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    WardrobeView()
}