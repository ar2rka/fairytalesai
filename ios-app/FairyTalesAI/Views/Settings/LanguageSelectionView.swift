import SwiftUI

struct LanguageSelectionView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            List {
                ForEach(["English", "Russian", "Spanish", "French"], id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            Spacer()
                            if selectedLanguage == language {
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
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
