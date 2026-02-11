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
        VStack(spacing: 0) {
            // Top edge — subtle divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.25),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 0.5)

            // Background: material + tint
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Rectangle()
                    .fill(AppTheme.darkPurple.opacity(0.65))
            }
            .frame(height: 76)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .bottom) {
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "house.fill",
                    label: localizer.tabHome,
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                TabBarButton(
                    icon: "book.closed.fill",
                    label: localizer.tabLibrary,
                    isSelected: selectedTab == 1,
                    action: { selectedTab = 1 }
                )
                TabBarButton(
                    icon: "wand.and.stars",
                    label: localizer.tabCreate,
                    isSelected: false,
                    action: onCreateTapped
                )
                TabBarButton(
                    icon: "person.fill",
                    label: localizer.tabProfile,
                    isSelected: selectedTab == 3,
                    action: { selectedTab = 3 }
                )
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .frame(height: 76.5)
        .edgesIgnoringSafeArea(.bottom)
    }
}

#Preview {
    CustomTabBar(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}
