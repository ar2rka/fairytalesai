import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.darkPurple.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // User Profile Section
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                    )
                                
                                Circle()
                                    .fill(AppTheme.primaryPurple)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "pencil")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 4, y: 4)
                            }
                            
                            VStack(spacing: 4) {
                                Text(authService.userEmail ?? "User")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .lineLimit(1)
                                
                                if let userEmail = authService.userEmail {
                                    Text(userEmail)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(AppTheme.cornerRadius)
                        .padding(.horizontal)
                        .padding(.top)
                        
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
                                    SettingsRow(
                                        icon: "star.fill",
                                        iconColor: Color.yellow,
                                        iconBackground: AppTheme.primaryPurple,
                                        title: "Storyteller Pro",
                                        subtitle: "Active Plan",
                                        subtitleColor: Color.pink,
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
                        Button(action: { showLogoutAlert = true }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                } else {
                                    Text("Выйти")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(AppTheme.cornerRadius)
                        }
                        .disabled(authService.isLoading)
                        .opacity(authService.isLoading ? 0.6 : 1.0)
                        .padding(.horizontal)
                        .alert("Выход", isPresented: $showLogoutAlert) {
                            Button("Отмена", role: .cancel) { }
                            Button("Выйти", role: .destructive) {
                                handleLogout()
                            }
                        } message: {
                            Text("Вы уверены, что хотите выйти из аккаунта?")
                        }
                        
                        // Version Info
                        Text("Version 1.0.2 (Build 2024)")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func handleLogout() {
        Task {
            do {
                try await authService.signOut()
            } catch {
                // Error is handled by AuthService
            }
        }
    }
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

