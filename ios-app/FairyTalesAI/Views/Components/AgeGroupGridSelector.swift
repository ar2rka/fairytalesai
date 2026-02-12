import SwiftUI

struct AgeGroupGridSelector: View {
    @Binding var selectedCategory: AgeCategory
    @State private var selectedIndex: Int = 0
    
    private var ageOptions: [(category: AgeCategory, emoji: String, name: String, range: String)] {
        let localizer = LocalizationManager.shared
        return [
            (.twoThree, "👶", localizer.ageToddler, localizer.ageToddlerRange),
            (.threeFive, "🎨", localizer.agePreschool, localizer.agePreschoolRange),
            (.fiveSeven, "🏫", localizer.ageExplorer, localizer.ageExplorerRange),
            (.eightPlus, "📚", localizer.ageBigKid, localizer.ageBigKidRange)
        ]
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(Array(ageOptions.enumerated()), id: \.element.category) { index, option in
                AgeGroupCard(
                    emoji: option.emoji,
                    name: option.name,
                    range: option.range,
                    isSelected: selectedIndex == index
                ) {
                    HapticFeedback.impact()
                    selectedIndex = index
                    selectedCategory = option.category
                }
            }
        }
        .onAppear {
            // Find initial selected index
            if let index = ageOptions.firstIndex(where: { $0.category == selectedCategory }) {
                selectedIndex = index
            }
        }
        .onChange(of: selectedCategory) { _, newValue in
            if let index = ageOptions.firstIndex(where: { $0.category == newValue }) {
                selectedIndex = index
            }
        }
    }
}

struct AgeGroupCard: View {
    let emoji: String
    let name: String
    let range: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 32))
                
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: nil))
                
                Text(range)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.textSecondary(for: nil))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        AppTheme.cardBackground(for: nil)
                    }
                }
            )
            .cornerRadius(AppTheme.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(
                        isSelected ? Color.clear : AppTheme.primaryPurple.opacity(0.2),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isSelected ? AppTheme.primaryPurple.opacity(0.3) : Color.clear,
                radius: isSelected ? 8 : 0,
                x: 0,
                y: isSelected ? 4 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AgeGroupGridSelector(selectedCategory: .constant(.threeFive))
        .padding()
        .preferredColorScheme(.dark)
}
