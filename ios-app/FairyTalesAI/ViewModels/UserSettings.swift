import Foundation
import SwiftUI

class UserSettings: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    
    @Published var onboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(onboardingComplete, forKey: "onboardingComplete")
        }
    }
    
    @Published var isPremium: Bool {
        didSet {
            UserDefaults.standard.set(isPremium, forKey: "isPremium")
        }
    }
    
    @Published var freeGenerationsRemaining: Int {
        didSet {
            UserDefaults.standard.set(freeGenerationsRemaining, forKey: "freeGenerationsRemaining")
        }
    }
    
    @Published var storyFontSize: CGFloat {
        didSet {
            UserDefaults.standard.set(storyFontSize, forKey: "storyFontSize")
        }
    }
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selectedLanguage")
        }
    }
    
    // Возвращает код языка для API (например, "en", "ru", "es", "fr")
    var languageCode: String {
        switch selectedLanguage.lowercased() {
        case "english", "английский":
            return "en"
        case "russian", "русский":
            return "ru"
        case "spanish", "испанский":
            return "es"
        case "french", "французский":
            return "fr"
        default:
            return "en"
        }
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        self.isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        // Initialize to 1 for demo, or load from UserDefaults if exists
        if UserDefaults.standard.object(forKey: "freeGenerationsRemaining") == nil {
            self.freeGenerationsRemaining = 1
        } else {
            self.freeGenerationsRemaining = UserDefaults.standard.integer(forKey: "freeGenerationsRemaining")
        }
        // Initialize story font size (default 16, range 12-24)
        if UserDefaults.standard.object(forKey: "storyFontSize") == nil {
            self.storyFontSize = 16.0
        } else {
            self.storyFontSize = CGFloat(UserDefaults.standard.double(forKey: "storyFontSize"))
        }
        // Initialize selected language (default "English")
        if let language = UserDefaults.standard.string(forKey: "selectedLanguage") {
            self.selectedLanguage = language
        } else {
            self.selectedLanguage = "English"
        }
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        onboardingComplete = true
    }
    
    func startFreeTrial() {
        isPremium = true
        hasCompletedOnboarding = true
        onboardingComplete = true
        // In production, this would trigger the actual subscription flow
    }
    
    func useFreeGeneration() {
        if freeGenerationsRemaining > 0 {
            freeGenerationsRemaining -= 1
        }
    }
    
    func canGenerateStory(duration: Int) -> Bool {
        // Premium users can always generate
        if isPremium {
            return true
        }
        
        // Free users can only generate stories up to 5 minutes
        if duration > 5 {
            return false
        }
        
        // Check if they have free generations remaining
        return freeGenerationsRemaining > 0
    }
}

