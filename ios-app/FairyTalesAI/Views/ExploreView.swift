import SwiftUI

struct ExploreView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCategory: String? = nil
    
    // Featured content
    private let featuredPrompt = "A brave little astronaut discovers a friendly alien on a candy planet"
    private let characterOfTheDay = "Luna the Star Explorer"
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Feature Card
                    FeaturedStoryIdeaCard(
                        prompt: featuredPrompt,
                        character: characterOfTheDay
                    )
                    .padding(.horizontal)
                    .padding(.top, -50)
                    
                    // New Characters - Horizontal Scroll
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Characters")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(["Alex the Brave", "Maya the Explorer", "Sam the Wizard", "Zoe the Pirate"], id: \.self) { character in
                                    CharacterCard(name: character)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Trending Themes - Horizontal Scroll
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trending Themes")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(StoryTheme.allThemes.prefix(6)) { theme in
                                    ExploreThemeCard(theme: theme)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Staff Picks - Horizontal Scroll
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Staff Picks")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(["The Enchanted Forest", "Dragon's Treasure", "Magic School Adventure"], id: \.self) { pick in
                                    StaffPickCard(title: pick)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct FeaturedStoryIdeaCard: View {
    let prompt: String
    let character: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text("Featured Story Idea")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Character of the Day")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(character)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(prompt)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(3)
            
            Button(action: {}) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Try this Prompt")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(AppTheme.primaryPurple)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct CharacterCard: View {
    let name: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Text(name.prefix(1))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 100, height: 36, alignment: .top) // Fixed height for consistent card sizes
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
        .frame(width: 130) // Fixed card width
        .frame(width: 120)
    }
}

struct ExploreThemeCard: View {
    let theme: StoryTheme
    @Environment(\.colorScheme) var colorScheme
    
    private var themeColor: Color {
        switch theme.name.lowercased() {
        case "space": return Color(red: 1.0, green: 0.65, blue: 0.0)
        case "pirates": return Color(red: 0.8, green: 0.6, blue: 0.2)
        case "dinosaurs": return Color(red: 0.2, green: 0.8, blue: 0.2)
        case "mermaids": return Color(red: 0.2, green: 0.6, blue: 1.0)
        case "animals": return Color(red: 0.4, green: 0.7, blue: 0.3)
        case "mystery": return Color(red: 0.6, green: 0.3, blue: 0.8)
        case "magic school": return Color(red: 0.8, green: 0.3, blue: 0.8)
        case "robots": return Color(red: 0.5, green: 0.5, blue: 0.5)
        default: return AppTheme.primaryPurple
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(theme.emoji)
                .font(.system(size: 40))
            
            Text(theme.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(1)
        }
        .frame(width: 120, height: 120)
        .background(themeColor.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                .stroke(themeColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(AppTheme.cornerRadius)
    }
}

struct StaffPickCard: View {
    let title: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.primaryPurple)
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(2)
            
            Text("Staff Favorite")
                .font(.system(size: 12))
                .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
        }
        .padding()
        .frame(width: 180, height: 140)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
}

#Preview {
    ExploreView()
}
