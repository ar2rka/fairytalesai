import SwiftUI

struct ChildProfileCircle: View {
    let child: Child
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    Text(child.name.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(child.name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
        }
    }
}
