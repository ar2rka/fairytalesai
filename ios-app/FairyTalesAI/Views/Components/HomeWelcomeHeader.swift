import SwiftUI

/// Welcome header at the top of HomeView.
struct HomeWelcomeHeader: View {
    var headerTitleSize: CGFloat = 32
    var welcomeSize: CGFloat = 16
    var isCompactPhone: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizationManager.shared.homeWelcome)
                .font(.system(size: welcomeSize, weight: .medium))
                .foregroundColor(Color(white: 0.85))
            
            Text(LocalizationManager.shared.homeCreateMagicalStories)
                .font(.system(size: headerTitleSize, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
        }
        .padding(.top, isCompactPhone ? 6 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, isCompactPhone ? 4 : 8)
        .background(
            GeometryReader { headerGeo in
                Color.clear.preference(
                    key: ContentMinYPreferenceKey.self,
                    value: headerGeo.frame(in: .named("scroll")).minY
                )
            }
        )
    }
}
