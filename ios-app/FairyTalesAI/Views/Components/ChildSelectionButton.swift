import SwiftUI

struct ChildSelectionButton: View {
    let child: Child
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Text(child.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppTheme.textPrimary(for: colorScheme))
                
                Text(child.ageCategory.shortName)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Color(white: 0.85)) // Lighter for better contrast
            }
            .padding()
            .frame(width: 100)
            .background(isSelected ? AppTheme.primaryPurple : AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(25)
            .overlay(
                Group {
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.white)
                                    .padding(8)
                            }
                            Spacer()
                        }
                    }
                }
            )
        }
    }
}
