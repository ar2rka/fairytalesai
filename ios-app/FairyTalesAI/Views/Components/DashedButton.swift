import SwiftUI

struct DashedButton: View {
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(AppTheme.primaryPurple)
        .padding()
        .frame(width: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(AppTheme.primaryPurple)
        )
    }
}
