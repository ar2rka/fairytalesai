import SwiftUI

struct MagicSegmentedSelector: View {
    @Binding var selectedCategory: AgeCategory
    @State private var selectedIndex: Int = 0
    @State private var containerWidth: CGFloat = 0
    
    private let ageOptions: [(category: AgeCategory, emoji: String, name: String, range: String)] = [
        (.twoThree, "👶", "Toddler", "1-2 years"),
        (.threeFive, "🎨", "Preschool", "3-5 years"),
        (.fiveSeven, "🏫", "Explorer", "6-8 years"),
        (.eightPlus, "📚", "Big Kid", "9+ years")
    ]
    
    private var segmentWidth: CGFloat {
        guard containerWidth > 0 else { return 0 }
        return containerWidth / CGFloat(ageOptions.count)
    }
    
    private var indicatorOffset: CGFloat {
        return segmentWidth * CGFloat(selectedIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(AppTheme.cardBackground(for: nil))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.primaryPurple.opacity(0.2), lineWidth: 1)
                    )
                
                // Sliding indicator
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: segmentWidth - 4)
                    .offset(x: indicatorOffset + 2)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: indicatorOffset)
                
                // Segments
                HStack(spacing: 0) {
                    ForEach(Array(ageOptions.enumerated()), id: \.element.category) { index, option in
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            
                            selectedIndex = index
                            selectedCategory = option.category
                        }) {
                            VStack(spacing: 6) {
                                Text("\(option.emoji) \(option.name)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedIndex == index ? .white : Color(white: 0.7))
                                
                                Text(option.range)
                                    .font(.system(size: 13))
                                    .foregroundColor(selectedIndex == index ? .white.opacity(0.9) : Color(white: 0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .onAppear {
                containerWidth = geometry.size.width
                // Find initial selected index
                if let index = ageOptions.firstIndex(where: { $0.category == selectedCategory }) {
                    selectedIndex = index
                }
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                containerWidth = newWidth
            }
            .onChange(of: selectedCategory) { _, newValue in
                if let index = ageOptions.firstIndex(where: { $0.category == newValue }) {
                    selectedIndex = index
                }
            }
        }
        .frame(height: 90)
    }
}

#Preview {
    MagicSegmentedSelector(selectedCategory: .constant(.threeFive))
        .padding()
        .preferredColorScheme(.dark)
}
