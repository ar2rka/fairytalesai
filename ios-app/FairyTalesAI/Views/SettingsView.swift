import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    @State private var showLogoutAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    private var themeMode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRaw) ?? .system }
        set { themeModeRaw = newValue.rawValue }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        userProfileSection
                        
                        appExperienceSection
                        
                        membershipSection
                        
                        supportLegalSection
                        
                        logoutButton
                        
                        // Version Info
                        Text("Version 1.0.2 (Build 2024)")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var userProfileSection: some View {
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
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    .lineLimit(1)
                
                if let userEmail = authService.userEmail {
                    Text(userEmail)
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .lineLimit(1)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground(for: colorScheme))
        .cornerRadius(AppTheme.cornerRadius)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var appExperienceSection: some View {
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
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
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
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                NavigationLink(destination: ThemeSelectionView(selectedTheme: Binding(
                    get: { ThemeMode(rawValue: themeModeRaw) ?? .system },
                    set: { themeModeRaw = $0.rawValue }
                ))) {
                    SettingsRow(
                        icon: "paintbrush.fill",
                        iconColor: Color.orange,
                        title: "Appearance",
                        trailing: {
                            HStack {
                                Text(themeMode.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryPurple)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
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
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .padding(.horizontal)
        }
    }
    
    private var membershipSection: some View {
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
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
                    .padding(.leading, 60)
                
                NavigationLink(destination: SubscriptionView()) {
                    SettingsRow(
                        icon: "creditcard.fill",
                        iconColor: AppTheme.primaryPurple,
                        title: "Manage Subscription",
                        trailing: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .padding(.horizontal)
        }
    }
    
    private var supportLegalSection: some View {
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
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
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
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(AppTheme.textSecondary(for: colorScheme).opacity(0.3))
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
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
            .padding(.horizontal)
        }
    }
    
    private var logoutButton: some View {
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
            .background(AppTheme.cardBackground(for: colorScheme))
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
