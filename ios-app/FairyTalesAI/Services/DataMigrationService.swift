import Foundation
import SwiftUI

/// Handles migration of guest data to cloud account after registration
@MainActor
class DataMigrationService: ObservableObject {
    static let shared = DataMigrationService()
    
    private let guestDataManager = GuestDataManager.shared
    private let childrenService = ChildrenService.shared
    private let storiesService = StoriesService.shared
    
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationError: String?
    
    /// Migrates all guest data to the authenticated user's account
    func migrateGuestDataToCloud(userId: UUID) async throws {
        isMigrating = true
        migrationProgress = 0.0
        migrationError = nil
        
        defer {
            isMigrating = false
        }
        
        do {
            // Step 1: Migrate children (30% progress)
            let guestChildren = guestDataManager.loadGuestChildren()
            var migratedChildren: [Child] = []
            
            for (index, child) in guestChildren.enumerated() {
                do {
                    let migratedChild = try await childrenService.createChild(child, userId: userId)
                    migratedChildren.append(migratedChild)
                    migrationProgress = 0.3 + (Double(index + 1) / Double(guestChildren.count)) * 0.2
                } catch {
                    print("⚠️ Failed to migrate child \(child.name): \(error.localizedDescription)")
                    // Continue with other children even if one fails
                }
            }
            
            // Step 2: Migrate stories (50% - 90% progress)
            let guestStories = guestDataManager.loadGuestStories()
            
            for (index, story) in guestStories.enumerated() {
                do {
                    // Update story with migrated child ID if applicable
                    var storyToMigrate = story
                    if let childId = story.childId,
                       let migratedChild = migratedChildren.first(where: { $0.id == childId }) {
                        storyToMigrate = Story(
                            id: story.id,
                            title: story.title,
                            content: story.content,
                            childId: migratedChild.id,
                            theme: story.theme,
                            duration: story.duration,
                            plot: story.plot,
                            createdAt: story.createdAt,
                            favoriteStatus: story.favoriteStatus
                        )
                    }
                    
                    try await storiesService.createStory(storyToMigrate, userId: userId)
                    migrationProgress = 0.5 + (Double(index + 1) / Double(guestStories.count)) * 0.4
                } catch {
                    print("⚠️ Failed to migrate story \(story.title): \(error.localizedDescription)")
                    // Continue with other stories even if one fails
                }
            }
            
            // Step 3: Clear guest data (90% - 100% progress)
            guestDataManager.clearGuestData()
            migrationProgress = 1.0
            
        } catch {
            migrationError = error.localizedDescription
            throw error
        }
    }
}
