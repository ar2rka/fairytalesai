import SwiftUI

struct ThemeSelectionView: View {
    @Binding var selectedTheme: ThemeMode
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            List {
                ForEach(ThemeMode.allCases, id: \.self) { theme in
                    Button(action: {
                        selectedTheme = theme
                        dismiss()
                    }) {
                        HStack {
                            Text(theme.displayName)
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            Spacer()
                            if selectedTheme == theme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.cardBackground(for: colorScheme))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
