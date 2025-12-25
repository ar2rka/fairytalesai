import SwiftUI

@main
struct FairyTalesAIApp: App {
    @StateObject private var childrenStore = ChildrenStore()
    @StateObject private var storiesStore = StoriesStore()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(childrenStore)
                .environmentObject(storiesStore)
                .preferredColorScheme(.dark)
        }
    }
}
