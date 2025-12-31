import SwiftUI

struct SettingsRow<Trailing: View>: View {
    let icon: String
    var iconColor: Color = AppTheme.primaryPurple
    var iconBackground: Color? = nil
    let title: String
    var subtitle: String? = nil
    var subtitleColor: Color = AppTheme.textSecondary(for: nil)
    @ViewBuilder let trailing: () -> Trailing
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            if let background = iconBackground {
                ZStack {
                    Circle()
                        .fill(background.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 18))
                }
            } else {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 20))
                    .frame(width: 40)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(subtitleColor)
                }
            }
            
            Spacer()
            
            trailing()
        }
        .padding()
    }
}
