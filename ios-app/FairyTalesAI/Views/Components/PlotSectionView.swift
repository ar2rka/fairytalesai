import SwiftUI

/// Plot text editor section used in GenerateStoryView.
struct PlotSectionView: View {
    @Binding var plot: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.generateStoryBriefPlot)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $plot)
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 120)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(25)
                    .overlay(alignment: .topLeading) {
                        if plot.isEmpty {
                            Text(LocalizationManager.shared.generateStoryPlotPlaceholder)
                                .font(.system(size: 16, weight: .regular))
                                .italic()
                                .foregroundColor(Color(red: 0.72, green: 0.75, blue: 0.8))
                                .multilineTextAlignment(.leading)
                                .padding(12)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
        .padding(.horizontal)
    }
}
