import Foundation
import SwiftUI

/// Manages local storage for guest user data
@MainActor
class GuestDataManager: ObservableObject {
    static let shared = GuestDataManager()
    
    private let childrenKey = "guest_children"
    private let storiesKey = "guest_stories"
    
    // MARK: - Children Management
    
    func saveGuestChildren(_ children: [Child]) {
        if let encoded = try? JSONEncoder().encode(children) {
            UserDefaults.standard.set(encoded, forKey: childrenKey)
        }
    }
    
    func loadGuestChildren() -> [Child] {
        guard let data = UserDefaults.standard.data(forKey: childrenKey),
              let decoded = try? JSONDecoder().decode([Child].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Stories Management
    
    func saveGuestStories(_ stories: [Story]) {
        if let encoded = try? JSONEncoder().encode(stories) {
            UserDefaults.standard.set(encoded, forKey: storiesKey)
        }
    }
    
    func loadGuestStories() -> [Story] {
        guard let data = UserDefaults.standard.data(forKey: storiesKey),
              let decoded = try? JSONDecoder().decode([Story].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Clear Guest Data
    
    func clearGuestData() {
        UserDefaults.standard.removeObject(forKey: childrenKey)
        UserDefaults.standard.removeObject(forKey: storiesKey)
    }
    
    // MARK: - Check if Guest Data Exists
    
    var hasGuestData: Bool {
        !loadGuestChildren().isEmpty || !loadGuestStories().isEmpty
    }
}
