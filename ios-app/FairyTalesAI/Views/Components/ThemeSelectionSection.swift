import SwiftUI

/// Theme selection grid + "See All Themes" toggle used in GenerateStoryView.
struct ThemeSelectionSection: View {
    @Binding var selectedTheme: StoryTheme?
    @Binding var showAllThemes: Bool
    var selectedChild: Child?
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizationManager.shared.generateStoryChooseTheme)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            if showAllThemes {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(StoryTheme.allThemes, id: \.name) { theme in
                        ThemeSelectionButton(
                            theme: theme,
                            isSelected: selectedTheme?.name == theme.name
                        ) {
                            selectedTheme = selectedTheme?.name == theme.name ? nil : theme
                        }
                    }
                }
            } else {
                HStack(alignment: .top, spacing: 10) {
                    ForEach(StoryTheme.visibleThemes(for: selectedChild), id: \.name) { theme in
                        ThemeSelectionButton(
                            theme: theme,
                            isSelected: selectedTheme?.name == theme.name
                        ) {
                            selectedTheme = selectedTheme?.name == theme.name ? nil : theme
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        
        // See all / Show less toggle
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                showAllThemes.toggle()
            }
        }) {
            HStack(spacing: 4) {
                if showAllThemes {
                    Text(LocalizationManager.shared.generateStoryShowLess)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                } else {
                    Text(LocalizationManager.shared.generateStorySeeAllThemes)
                    Text(LocalizationManager.shared.generateStoryMoreThemes)
                        .foregroundColor(Color(white: 0.55))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.primaryPurple)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal)
        .padding(.top, 2)
    }
}
