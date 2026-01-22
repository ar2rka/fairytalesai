import SwiftUI
import Foundation

// Helper extension for rounded corners on specific sides
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var onCreateTapped: () -> Void = {}
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("selectedLanguage") private var selectedLanguage: String = "English"
    
    private var localizer: LocalizationManager {
        LocalizationManager.shared
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background - solid bar touching both sides
            VStack(spacing: 0) {
                // Top divider line
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(.white.opacity(0.2))
                
                // Main background - extends to edges
                AppTheme.cardBackground(for: colorScheme)
                    .frame(height: 64.5)
            }
            .frame(maxWidth: .infinity)
            .edgesIgnoringSafeArea(.bottom)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
            
            // Tab Buttons
            HStack(spacing: 0) {
                // Tab 0: Home
                TabBarButton(
                    icon: "house.fill",
                    label: localizer.tabHome,
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                
                // Tab 1: Library
                TabBarButton(
                    icon: "book.closed.fill",
                    label: localizer.tabLibrary,
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                
                // Spacer for center button
                Spacer()
                    .frame(width: 70)
                
                // Tab 3: Explore
                TabBarButton(
                    icon: "sparkles",
                    label: localizer.tabExplore,
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
                
                // Tab 4: Profile
                TabBarButton(
                    icon: "person.fill",
                    label: localizer.tabProfile,
                    isSelected: selectedTab == 4,
                    action: { selectedTab = 4 }
                )
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            
            // Elevated Center Button - Floats above the bar
            CenterCreateButton(
                isSelected: false,
                action: onCreateTapped
            )
            .offset(y: -15) // Lowered to be closer to the nav bar
        }
        .frame(height: 65)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    .frame(height: 22) // Fixed height for alignment
                
                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.primaryPurple : AppTheme.textSecondary(for: colorScheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // Make entire area tappable
        }
    }
}

struct CenterCreateButton: View {
    let isSelected: Bool
    let action: () -> Void
    @State private var breathingScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: AppTheme.primaryPurple.opacity(0.4), radius: 10, x: 0, y: 5)
                
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(breathingScale)
        }
        .onAppear {
            // Breathing animation: scale from 1.0 to 1.05 and back every 3 seconds
            withAnimation(
                Animation.easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true)
            ) {
                breathingScale = 1.05
            }
        }
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}
