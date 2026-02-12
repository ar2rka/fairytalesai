import SwiftUI

/// Duration slider section used in GenerateStoryView.
struct DurationSectionView: View {
    @Binding var selectedDuration: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationManager.shared.generateStoryDuration)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("\(Int(selectedDuration))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.primaryPurple)
                    Text(LocalizationManager.shared.generateStoryMin)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
            }
            
            VStack(spacing: 8) {
                Slider(
                    value: $selectedDuration,
                    in: 3...5,
                    step: 1
                ) {
                    Text(LocalizationManager.shared.generateStoryDuration)
                } minimumValueLabel: {
                    Text("3")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                } maximumValueLabel: {
                    Text("5")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                }
                .tint(AppTheme.primaryPurple)
            }
        }
        .padding(.horizontal)
    }
}
