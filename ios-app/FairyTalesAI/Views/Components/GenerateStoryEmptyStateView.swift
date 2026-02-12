import SwiftUI

/// Empty state shown in GenerateStoryView when the user has no child profiles.
struct GenerateStoryEmptyStateView: View {
    @Binding var showingAddChild: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.fill.badge.plus")
                .font(.system(size: 80, weight: .light))
                .foregroundColor(AppTheme.primaryPurple.opacity(0.6))
                .symbolEffect(.pulse, options: .repeating)
            
            Text(LocalizationManager.shared.generateStoryWhoIsHeroToday)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            Text(LocalizationManager.shared.generateStoryNeedProfile)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { showingAddChild = true }) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text(LocalizationManager.shared.generateStoryCreateProfile)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(AppTheme.cornerRadius)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
