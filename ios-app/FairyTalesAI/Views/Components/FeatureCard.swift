import SwiftUI

struct FeatureCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.homeSparkNewAdventure)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            Text("Create a custom fairy tale instantly with the power of AI magic.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            
            HStack {
                Image(systemName: "sparkles")
                Text(LocalizationManager.shared.homeCreateNewTale)
                    .font(.system(size: 16, weight: .semibold))
                Image(systemName: "sparkles")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.primaryPurple)
            .cornerRadius(AppTheme.cornerRadius)
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
    }
}
