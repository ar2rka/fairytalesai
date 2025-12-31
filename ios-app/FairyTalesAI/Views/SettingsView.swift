import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @State private var showingShareSheet = false
    @State private var showingAddChild = false
    
    var body: some View {
        ZStack {
            AppTheme.darkPurple.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Section
                    HStack(spacing: 16) {
                        ZStack(alignment: .bottomTrailing) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 65, height: 65)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.white)
                                )
                            
                            Circle()
                                .fill(AppTheme.primaryPurple)
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 2, y: 2)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sarah Anderson")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text("sarah.anderson@example.com")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(AppTheme.cornerRadius)
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Children Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CHILDREN")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryPurple)
                            .padding(.horizontal)
                        
                        if childrenStore.children.isEmpty {
                            VStack(spacing: 12) {
                                Text("No children added yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                
                                Button(action: { showingAddChild = true }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add a new child")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.primaryPurple)
                                    .cornerRadius(AppTheme.cornerRadius)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(childrenStore.children) { child in
                                    NavigationLink(destination: EditChildView(child: child)) {
                                        ChildCardView(child: child)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                Button(action: { showingAddChild = true }) {
                                    HStack {
                                        Image(systemName: "plus")
                                        Text("Add a new child")
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.primaryPurple)
                                    .cornerRadius(AppTheme.cornerRadius)
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                            .padding(.horizontal)
                        }
                    }
                    
                    // App Experience Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APP EXPERIENCE")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryPurple)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "bell.fill",
                                iconColor: AppTheme.primaryPurple,
                                title: "Push Notifications",
                                trailing: {
                                    Toggle("", isOn: $pushNotificationsEnabled)
                                        .tint(AppTheme.primaryPurple)
                                }
                            )
                            
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.3))
                                .padding(.leading, 60)
                            
                            SettingsRow(
                                icon: "music.note",
                                iconColor: Color.pink,
                                title: "Sound Effects",
                                trailing: {
                                    Toggle("", isOn: $soundEffectsEnabled)
                                        .tint(AppTheme.primaryPurple)
                                }
                            )
                            
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.3))
                                .padding(.leading, 60)
                            
                            NavigationLink(destination: LanguageSelectionView()) {
                                SettingsRow(
                                    icon: "globe",
                                    iconColor: Color.blue,
                                    title: "Language",
                                    trailing: {
                                        HStack {
                                            Text(selectedLanguage)
                                                .font(.system(size: 14))
                                                .foregroundColor(AppTheme.primaryPurple)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                    }
                    
                    // Membership Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("MEMBERSHIP")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryPurple)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: MembershipView()) {
                                ZStack {
                                    SettingsRow(
                                        icon: "star.fill",
                                        iconColor: Color.yellow,
                                        iconBackground: AppTheme.primaryPurple,
                                        title: "Storyteller Pro",
                                        subtitle: "Active Plan",
                                        subtitleColor: Color.green,
                                        trailing: {
                                            HStack(spacing: 8) {
                                                // Pro Badge
                                                Text("PRO")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(
                                                        LinearGradient(
                                                            colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .cornerRadius(8)
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppTheme.textSecondary)
                                            }
                                        }
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.3))
                                .padding(.leading, 60)
                            
                            NavigationLink(destination: SubscriptionView()) {
                                SettingsRow(
                                    icon: "creditcard.fill",
                                    iconColor: AppTheme.primaryPurple,
                                    title: "Manage Subscription",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                    }
                    
                    // Community Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SPREAD THE MAGIC")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryPurple)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            Button(action: { showingShareSheet = true }) {
                                SettingsRow(
                                    icon: "person.2.fill",
                                    iconColor: .orange,
                                    title: "Invite a Parent Friend",
                                    subtitle: "Give magic, get credits",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                    }
                    
                    // Support & Legal Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SUPPORT & LEGAL")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryPurple)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: HelpCenterView()) {
                                SettingsRow(
                                    icon: "questionmark.circle.fill",
                                    iconColor: Color.green,
                                    iconBackground: AppTheme.primaryPurple,
                                    title: "Help Center",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.3))
                                .padding(.leading, 60)
                            
                            NavigationLink(destination: PrivacyPolicyView()) {
                                SettingsRow(
                                    icon: "lock.fill",
                                    iconColor: Color.gray,
                                    iconBackground: AppTheme.primaryPurple,
                                    title: "Privacy Policy",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .background(AppTheme.textSecondary.opacity(0.3))
                                .padding(.leading, 60)
                            
                            NavigationLink(destination: TermsView()) {
                                SettingsRow(
                                    icon: "doc.text.fill",
                                    iconColor: Color.gray,
                                    iconBackground: AppTheme.primaryPurple,
                                    title: "Terms of Service",
                                    trailing: {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.textSecondary)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                    }
                    
                    // Log Out Button
                    Button(action: {}) {
                        Text("Log Out")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                    }
                    .padding(.horizontal)
                    
                    // Version Info
                    Text("Version 1.0.2 (Build 2024)")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [
                "Check out FairyTalesAI - Create magical personalized stories for your child! ✨",
                URL(string: "https://apps.apple.com/app/fairytalesai") ?? URL(string: "https://fairytalesai.com")!
            ])
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
        }
    }
    
    
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]
        let applicationActivities: [UIActivity]? = nil
        
        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: applicationActivities
            )
            return controller
        }
        
        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
    }
    
    struct SettingsRow<Trailing: View>: View {
        let icon: String
        var iconColor: Color = AppTheme.primaryPurple
        var iconBackground: Color? = nil
        let title: String
        var subtitle: String? = nil
        var subtitleColor: Color = AppTheme.textSecondary
        @ViewBuilder let trailing: () -> Trailing
        
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
                        .foregroundColor(AppTheme.textPrimary)
                    
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
    
    // Placeholder views for navigation destinations
    struct LanguageSelectionView: View {
        @AppStorage("selectedLanguage") private var selectedLanguage = "English"
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            List {
                ForEach(["English", "Russian", "Spanish", "French"], id: \.self) { language in
                    Button(action: {
                        selectedLanguage = language
                        dismiss()
                    }) {
                        HStack {
                            Text(language)
                                .foregroundColor(AppTheme.textPrimary)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppTheme.primaryPurple)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct MembershipView: View {
        var body: some View {
            Text("Membership Details")
                .navigationTitle("Storyteller Pro")
        }
    }
    
    struct SubscriptionView: View {
        var body: some View {
            Text("Manage Subscription")
                .navigationTitle("Subscription")
        }
    }
    
    struct HelpCenterView: View {
        var body: some View {
            Text("Help Center")
                .navigationTitle("Help Center")
        }
    }
    
    struct PrivacyPolicyView: View {
        var body: some View {
            Text("Privacy Policy")
                .navigationTitle("Privacy Policy")
        }
    }
    
    struct TermsView: View {
        var body: some View {
            Text("Terms of Service")
                .navigationTitle("Terms of Service")
        }
    }
    
    struct ChildCardView: View {
        let child: Child
        
        var body: some View {
            HStack(spacing: 16) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(child.name.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(child.ageCategory.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
    
    struct EditChildView: View {
        let child: Child
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            AddChildView(child: child)
        }
    }
    
    
}
