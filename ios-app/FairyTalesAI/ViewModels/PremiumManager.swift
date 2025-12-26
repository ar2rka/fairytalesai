import Foundation
import SwiftUI

class PremiumManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    // For demo purposes, default to false (free user)
    // In production, this would check subscription status
    init() {
        // Check UserDefaults for premium status
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
    
    func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: "isPremium")
    }
    
    // Sync with UserSettings
    func syncWithUserSettings(_ userSettings: UserSettings) {
        isPremium = userSettings.isPremium
    }
}



