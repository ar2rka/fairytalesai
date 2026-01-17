import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var authService: AuthService
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true
    @AppStorage("selectedLanguage") private var selectedLanguage = "English"
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    @Environment(\.colorScheme) var colorScheme
    @State private var showingShareSheet = false
    @State private var showingAddChild = false
    @State private var showLogoutAlert = false
    
    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Guest Mode Banner
                    if authService.isGuest {
                        GuestModeBanner()
                            .padding(.horizontal)
                            .padding(.top, 10)
                    } else {
                        // Add small top padding when no banner
                        Spacer()
                            .frame(height: 10)
                    }
                    
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
                                .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                            
                            Text("sarah.anderson@example.com")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground(for: colorScheme))
                    .cornerRadius(AppTheme.cornerRadius)
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Children Section
                    childrenSection
                    
                    // App Experience Section
                    appExperienceSection
                    
                    // Membership Section
                    membershipSection
                    
                    // Community Section
                    communitySection
                    
                    // Support & Legal Section
                    supportLegalSection
                    
                    // Log Out Button
                    logoutButton
                    
                    // Version Info
                    Text("Version 1.0.2 (Build 2024)")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                        .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [
                "Check out FairyTalesAI - Create magical personalized stories for your child! ✨",
                URL(string: "https://apps.apple.com/app/fairytalesai") ?? URL(string: "https://fairytalesai.com")!
            ])
        }
        .sheet(isPresented: $showingAddChild) {
            AddChildView()
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Выйти", role: .destructive) {
                Task {
                    do {
                        try await authService.signOut()
                    } catch {
                        // Error is handled by AuthService's errorMessage
                        print("Sign out error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CHILDREN")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryPurple)
                .padding(.horizontal)
            
            if childrenStore.children.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.primaryPurple.opacity(0.6))
                    
                    Text("Who is our hero today?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    
                    Text("Add a profile to start the adventure.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddChild = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Profile")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryPurple)
                        .cornerRadius(AppTheme.cornerRadius)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal)
                .background(AppTheme.cardBackground(for: colorScheme))
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
                .background(AppTheme.cardBackground(for: colorScheme))
                .cornerRadius(AppTheme.cornerRadius)
                .padding(.horizontal)
            }
        }
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
                    get: { themeMode },
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
                        subtitleColor: Color.green,
                        trailing: {
                            HStack(spacing: 8) {
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
                                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
                            }
                        }
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                
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
    
    private var communitySection: some View {
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
                    Text("Log Out")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.cardBackground(for: colorScheme))
            .cornerRadius(AppTheme.cornerRadius)
        }
        .padding(.horizontal)
    }
}

// MARK: - Helper Views

struct ChildCardView: View {
    let child: Child
    @Environment(\.colorScheme) var colorScheme
    
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
                    .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                
                Text(child.ageCategory.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary(for: colorScheme))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary(for: colorScheme))
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

struct GuestModeBanner: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.colorScheme) var colorScheme
    @State private var showingSignUp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppTheme.primaryPurple, AppTheme.pastelBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("✨ Save the Magic Forever")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Sync profiles and stories across all your devices.")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            Button(action: { showingSignUp = true }) {
                Text("Create Account")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(AppTheme.cornerRadius)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [AppTheme.primaryPurple, AppTheme.pastelBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.cornerRadius)
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authService)
                .environmentObject(DataMigrationService.shared)
        }
    }
}
