import SwiftUI

/// Button style for "Who is listening?" child selection: push-in scale + opacity pulse + subtle glow.
struct ChildSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
            .shadow(
                color: configuration.isPressed ? AppTheme.primaryPurple.opacity(0.45) : .clear,
                radius: configuration.isPressed ? 10 : 0,
                x: 0,
                y: 0
            )
    }
}

/// Avatar circle with the child's name label underneath. Uses `ChildAvatarView` internally.
struct ChildProfileCircle: View {
    let child: Child
    var isSelected: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 6) {
            ChildAvatarView(child: child, size: 50, isSelected: isSelected)
            
            Text(child.name)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .lineLimit(1)
        }
        .padding(6)
    }
}
