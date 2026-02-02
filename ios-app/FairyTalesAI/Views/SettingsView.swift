import SwiftUI
import UIKit
import AuthenticationServices

struct SettingsView: View {
    @EnvironmentObject var childrenStore: ChildrenStore
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var userSettings: UserSettings
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("themeMode") private var themeModeRaw = ThemeMode.system.rawValue
    @Environment(\.colorScheme) var colorScheme
    @State private var showingShareSheet = false
    @State private var showingAddChild = false
    @State private var showLogoutAlert = false
    @State private var showingProfileEdit = false
    
    private var themeMode: ThemeMode {
        ThemeMode(rawValue: themeModeRaw) ?? .system
    }
    
    // Check if user is logged in (has email, not anonymous)
    private var isLoggedInUser: Bool {
        return !authService.isAnonymousUser && authService.userEmail != nil
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Guest Mode Banner - show for anonymous users only
                    if authService.isAnonymousUser {
                        GuestModeBanner()
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    } else {
                        // Add small top padding when no banner
                        Spacer()
                            .frame(height: 10)
                    }
                    
                    // Parent Profile Card - show only for logged-in users
                    if isLoggedInUser {
                        ParentProfileCard(showingProfileEdit: $showingProfileEdit)
                            .padding(.horizontal)
                            .padding(.top, authService.isAnonymousUser ? 0 : 4)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                    
                    // Children Section
                    childrenSection
                    
                    // App Experience Section
                    appExperienceSection
                    
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
                .animation(.easeInOut(duration: 0.3), value: authService.isAnonymousUser)
                .animation(.easeInOut(duration: 0.3), value: authService.userEmail)
            }
        }
        .navigationTitle(LocalizationManager.shared.settingsAccount)
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
        .alert(LocalizationManager.shared.settingsLogOutAlert, isPresented: $showLogoutAlert) {
            Button(LocalizationManager.shared.settingsCancel, role: .cancel) { }
            Button(LocalizationManager.shared.settingsLogOutConfirm, role: .destructive) {
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
        .sheet(isPresented: $showingProfileEdit) {
            // Placeholder for profile editing view
            ProfileEditView()
                .environmentObject(authService)
        }
    }
    
    // MARK: - Sections
    
    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.settingsChildren)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryPurple)
                .padding(.horizontal)
            
            if childrenStore.children.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.fill.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(AppTheme.primaryPurple.opacity(0.6))
                    
                    Text(LocalizationManager.shared.homeWhoIsOurHero)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary(for: colorScheme))
                    
                    Text(LocalizationManager.shared.homeAddProfileDescription)
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.85)) // Lighter for better contrast
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddChild = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text(LocalizationManager.shared.homeAddProfile)
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
                            Text(LocalizationManager.shared.settingsAddNewChild)
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
            Text(LocalizationManager.shared.settingsAppExperience)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryPurple)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    iconColor: AppTheme.primaryPurple,
                    title: LocalizationManager.shared.settingsPushNotifications,
                    trailing: {
                        Toggle("", isOn: $pushNotificationsEnabled)
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
                        title: LocalizationManager.shared.settingsAppearance,
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
                        title: LocalizationManager.shared.settingsLanguage,
                        trailing: {
                            HStack {
                                Text(userSettings.selectedLanguage == "English" ? LocalizationManager.shared.languageEnglish : LocalizationManager.shared.languageRussian)
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
    
    private var communitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizationManager.shared.settingsSpreadTheMagic)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryPurple)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button(action: { showingShareSheet = true }) {
                    SettingsRow(
                        icon: "person.2.fill",
                        iconColor: .orange,
                        title: LocalizationManager.shared.settingsInviteParentFriend,
                        subtitle: LocalizationManager.shared.settingsGiveMagicGetCredits,
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
            Text(LocalizationManager.shared.settingsSupportLegal)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryPurple)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                NavigationLink(destination: HelpCenterView()) {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: Color.green,
                        iconBackground: AppTheme.primaryPurple,
                        title: LocalizationManager.shared.settingsHelpCenter,
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
                        title: LocalizationManager.shared.settingsPrivacyPolicy,
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
                        title: LocalizationManager.shared.settingsTermsOfService,
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
                    Text(LocalizationManager.shared.settingsLogOut)
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

