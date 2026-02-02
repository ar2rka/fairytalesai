import SwiftUI

struct AddChildView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var name: String = ""
    @State private var selectedStoryStyle: StoryStyle = .hero
    @State private var selectedAgeCategory: AgeCategory = .threeFive
    @State private var selectedInterests: Set<String> = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showStarAnimation = false
    
    let child: Child?
    
    init(child: Child? = nil) {
        self.child = child
    }
    
    // Hero Creator Interests
    private var heroInterests: [(name: String, emoji: String)] {
        let localizer = LocalizationManager.shared
        return [
            (localizer.interestDinosaurs, "🦖"),
            (localizer.interestSpace, "🚀"),
            (localizer.interestUnicorns, "🦄"),
            (localizer.interestCastles, "🏰"),
            (localizer.interestMystery, "🕵️"),
            (localizer.interestAnimals, "🦁")
        ]
    }
    
    // Age Group Options for Hero Creator
    private var ageGroups: [(category: AgeCategory, label: String)] {
        let localizer = LocalizationManager.shared
        return [
            (.twoThree, "\(localizer.ageToddler) (1-3)"),
            (.threeFive, "\(localizer.agePreschool) (3-5)"),
            (.fiveSeven, "\(localizer.ageExplorer) (5-7)"),
            (.eightPlus, "\(localizer.ageBigKid) (8+)")
        ]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Hero Name Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.addChildNameOfHero)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            TextField(LocalizationManager.shared.addChildEnterHeroName, text: $name)
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .fill(AppTheme.primaryPurple.opacity(0.15))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                        .stroke(AppTheme.primaryPurple.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Hero Type Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.addChildHeroType)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            ProtagonistStyleSelector(selectedStyle: $selectedStoryStyle)
                        }
                        .padding(.horizontal)
                        
                        // Age Group Section - Grid Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.addChildAgeGroup)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            AgeGroupGridSelector(selectedCategory: $selectedAgeCategory)
                        }
                        .padding(.horizontal)
                        
                        // Magic Ingredients - Interests
                        VStack(alignment: .leading, spacing: 12) {
                            Text(LocalizationManager.shared.addChildMagicIngredients)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            Text(LocalizationManager.shared.addChildSelectInterests)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(heroInterests, id: \.name) { interest in
                                    HeroInterestChip(
                                        name: interest.name,
                                        emoji: interest.emoji,
                                        isSelected: selectedInterests.contains(interest.name)
                                    ) {
                                        if selectedInterests.contains(interest.name) {
                                            selectedInterests.remove(interest.name)
                                        } else {
                                            selectedInterests.insert(interest.name)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Error Message
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                        
                        // Bottom spacing
                        Spacer(minLength: 20)
                    }
                    .padding(.bottom, 80)
                }
                
                // Star Particle Animation
                if showStarAnimation {
                    StarParticleAnimation()
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle(LocalizationManager.shared.addChildCreateHero)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(LocalizationManager.shared.addChildCancel) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizationManager.shared.addChildSave) {
                        Task {
                            await saveChildWithAnimation()
                        }
                    }
                    .foregroundColor(name.isEmpty ? AppTheme.textSecondary(for: colorScheme) : AppTheme.primaryPurple)
                    .disabled(name.isEmpty || isLoading)
                }
            }
            .onAppear {
                if let child = child {
                    name = child.name
                    // Map gender string to StoryStyle
                    switch child.gender {
                    case "boy":
                        selectedStoryStyle = .boy
                    case "girl":
                        selectedStoryStyle = .girl
                    default:
                        selectedStoryStyle = .hero
                    }
                    selectedAgeCategory = child.ageCategory
                    selectedInterests = Set(child.interests)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveChildWithAnimation() async {
        guard !name.isEmpty else { return }
        
        // Show star animation
        withAnimation {
            showStarAnimation = true
        }
        
        // Wait a moment for animation
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
        
        await saveChild()
        
        // Dismiss after animation
        dismiss()
    }
    
    private func saveChild() async {
        guard !name.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let interestsArray = Array(selectedInterests)
        
        do {
            // Map StoryStyle to gender string for backward compatibility
            let genderString = selectedStoryStyle.genderString
            
            if let existingChild = child {
                let updatedChild = Child(
                    id: existingChild.id,
                    name: name,
                    gender: genderString,
                    ageCategory: selectedAgeCategory,
                    interests: interestsArray,
                    userId: existingChild.userId,
                    createdAt: existingChild.createdAt,
                    updatedAt: Date()
                )
                try await childrenStore.updateChild(updatedChild)
            } else {
                let newChild = Child(
                    name: name,
                    gender: genderString,
                    ageCategory: selectedAgeCategory,
                    interests: interestsArray
                )
                _ = try await childrenStore.addChild(newChild)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
