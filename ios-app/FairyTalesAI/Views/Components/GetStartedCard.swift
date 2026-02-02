import SwiftUI

struct GetStartedCard: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAddChild = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.homeEveryStoryNeedsHero)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                .multilineTextAlignment(.leading)
            
            Button(action: { showingAddChild = true }) {
                HStack {
                    Image(systemName: "person.fill.badge.plus")
                    Text(LocalizationManager.shared.homeAddChildProfile)
                        .font(.system(size: 16, weight: .semibold))
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
        }
        .padding()
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
        }
    }
}
