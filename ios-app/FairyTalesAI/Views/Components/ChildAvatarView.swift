import SwiftUI

/// Reusable circle avatar showing the first letter of the child's name.
/// Used across the app in various sizes (36pt, 50pt, 100pt etc.)
struct ChildAvatarView: View {
    let child: Child
    var size: CGFloat = 50
    var isSelected: Bool = false
    
    private var fontSize: CGFloat {
        size * 0.4
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Text(child.name.prefix(1).uppercased())
                        .font(.system(size: fontSize, weight: .bold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: isSelected ? 3 : 0)
                        .frame(width: size, height: size)
                )
                .overlay(
                    Circle()
                        .stroke(AppTheme.primaryPurple, lineWidth: isSelected ? 5 : 0)
                        .frame(width: size + 6, height: size + 6)
                )
                .shadow(
                    color: isSelected ? AppTheme.primaryPurple.opacity(0.6) : .clear,
                    radius: isSelected ? 8 : 0,
                    x: 0,
                    y: 0
                )
        }
        .frame(
            width: size + (isSelected ? 10 : 6),
            height: size + (isSelected ? 10 : 6)
        )
    }
}
