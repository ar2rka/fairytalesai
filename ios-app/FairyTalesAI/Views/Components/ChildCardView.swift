import SwiftUI

struct ChildCardView: View {
    let child: Child
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            ChildAvatarView(child: child, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Text(child.ageCategory.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
    }
}
