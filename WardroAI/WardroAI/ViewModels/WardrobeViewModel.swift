import Foundation
import SwiftUI

@MainActor
class WardrobeViewModel: ObservableObject {
    @Published var items: [WardrobeItem] = []
    @Published var isLoading = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingAddItem = false
    
    private let repository = WardrobeRepository()
    private(set) var userId: UUID
    
    init(userId: UUID) {
        self.userId = userId
    }
    
    func updateUserId(_ newUserId: UUID) {
        self.userId = newUserId
    }
    
    // MARK: - Public Methods
    
    func loadItems() {
        isLoading = true
        
        Task {
            do {
                let fetchedItems = try await repository.fetchUserItems(userId: userId)
                
                await MainActor.run {
                    self.items = fetchedItems
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    func refreshItems() async {
        do {
            let fetchedItems = try await repository.fetchUserItems(userId: userId)
            self.items = fetchedItems
        } catch {
            self.errorMessage = error.localizedDescription
            self.showingError = true
        }
    }
    
    func deleteItem(_ item: WardrobeItem) {
        guard let itemId = item.id else { return }
        
        Task {
            do {
                try await repository.deleteItem(id: itemId)
                
                await MainActor.run {
                    self.items.removeAll { $0.id == itemId }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    func archiveItem(_ item: WardrobeItem) {
        guard let itemId = item.id else { return }
        
        Task {
            do {
                _ = try await repository.archiveItem(id: itemId)
                
                await MainActor.run {
                    self.items.removeAll { $0.id == itemId }
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }
    
    var hasItems: Bool {
        !items.isEmpty
    }
} 