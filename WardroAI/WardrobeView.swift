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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading wardrobe...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.isEmpty {
                    emptyStateView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                } else {
                    wardrobeGridView
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isEmpty)
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.showingAddItem = true
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .buttonStyle(.plain)
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
        VStack(spacing: 28) {
            VStack(spacing: 16) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(spacing: 8) {
                    Text("Your wardrobe is empty")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("Start building your digital wardrobe by adding your first item")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            Button("Add First Item") {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    viewModel.showingAddItem = true
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.headline)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
    }
    
    private var wardrobeGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.items) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        WardrobeItemCard(
                            item: item,
                            onDelete: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    viewModel.deleteItem(item)
                                }
                            }
                        )
                        .aspectRatio(0.75, contentMode: .fit) // Ensure consistent card proportions
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: item.id)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .refreshable {
            await viewModel.refreshItems()
        }
    }
}

#Preview {
    WardrobeView()
}