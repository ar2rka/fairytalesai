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

