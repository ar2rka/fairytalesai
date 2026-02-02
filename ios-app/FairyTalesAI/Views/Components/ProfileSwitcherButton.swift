import SwiftUI

struct ProfileSwitcherButton: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @State private var showingChildPicker = false
    
    var body: some View {
        if let firstChild = childrenStore.children.first {
            Button(action: { showingChildPicker = true }) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(firstChild.name.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            .sheet(isPresented: $showingChildPicker) {
                ChildPickerView()
                    .environmentObject(childrenStore)
            }
        } else {
            NavigationLink(destination: SettingsView()) {
                Circle()
                    .fill(AppTheme.cardBackground)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textPrimary)
                    )
            }
        }
    }
}
