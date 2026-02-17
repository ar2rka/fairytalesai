import SwiftUI

/// Empty state shown in GenerateStoryView when the user has no child profiles.
struct GenerateStoryEmptyStateView: View {
    @Binding var showingAddChild: Bool
    var onClose: (() -> Void)? = nil
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // Liquid glass close button – top right (inside safe area)
            if let onClose = onClose {
                Button(action: {
                    HapticFeedback.impact()
                    onClose()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                        .frame(width: 36, height: 36)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.textPrimary(for: colorScheme).opacity(0.3),
                                                AppTheme.textPrimary(for: colorScheme).opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            }
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 3)
                }
                .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 20))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
