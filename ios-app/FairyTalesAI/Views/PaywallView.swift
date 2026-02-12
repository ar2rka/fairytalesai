import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    @State private var isPulsing = false
    @State private var showingSignUp = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Background (same as onboarding)
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.1, blue: 0.3), // Deep Purple
                        Color(red: 0.05, green: 0.05, blue: 0.15)  // Midnight Blue
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Animation Area (Dynamic sizing - ~20% of screen)
                    ZStack {
                        // Glowing sparkles effect
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.10, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                            .blur(radius: 20)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.08, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.8))
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.06, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(height: geometry.size.height * 0.20)
                    .frame(maxWidth: .infinity)
                    
                    // Content Section (Dynamic sizing - fills remaining space)
                    VStack(alignment: .center, spacing: geometry.size.height * 0.012) {
                        // Headline
                        Text("Unlock Unlimited Magic!")
                            .font(.system(size: min(geometry.size.width * 0.08, 32), weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .padding(.horizontal, geometry.size.width * 0.08)
                            .padding(.top, geometry.size.height * 0.02)
                        
                        // Subheadline
                        Text("Your child's imagination knows no bounds. Subscribe to unlock everything.")
                            .font(.system(size: min(geometry.size.width * 0.04, 16), weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .padding(.horizontal, geometry.size.width * 0.08)
                            .padding(.top, geometry.size.height * 0.01)
                        
                        // Features List (Dynamic spacing, reduced to 4 items)
                        VStack(alignment: .leading, spacing: geometry.size.height * 0.012) {
                            PaywallFeatureRow(
                                icon: "sparkles",
                                text: "Unlimited Story Generations"
                            )
                            
                            PaywallFeatureRow(
                                icon: "speaker.wave.3.fill",
                                text: "Enchanting AI Narration"
                            )
                            
                            PaywallFeatureRow(
                                icon: "book.closed.fill",
                                text: "Longer, Epic Adventures (Up to 30 mins)"
                            )
                            
                            PaywallFeatureRow(
                                icon: "heart.fill",
                                text: "Save All Your Favorites Forever"
                            )
                        }
                        .padding(.horizontal, geometry.size.width * 0.08)
                        .padding(.top, geometry.size.height * 0.01)
                        
                        Spacer()
                        
                        // Primary CTA Button
                        Button(action: {
                            HapticFeedback.impact(.medium)
                            
                            // If anonymous user, show sign up first
                            if authService.isAnonymousUser {
                                showingSignUp = true
                            } else {
                                // Start free trial
                                userSettings.startFreeTrial()
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(authService.isAnonymousUser ? "Create Account to Subscribe" : "Start Your 7-Day Free Trial")
                                    .font(.system(size: min(geometry.size.width * 0.045, 18), weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, geometry.size.height * 0.022)
                            .background(
                                LinearGradient(
                                    colors: [
                                        AppTheme.primaryPurple,
                                        AppTheme.accentPurple
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(AppTheme.cornerRadius)
                            .scaleEffect(isPulsing ? 1.02 : 1.0)
                            .shadow(color: AppTheme.primaryPurple.opacity(0.5), radius: isPulsing ? 20 : 10)
                        }
                        .padding(.horizontal, geometry.size.width * 0.08)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                isPulsing = true
                            }
                        }
                        
                        // Secondary Action
                        Button(action: {
                            // Restore purchases
                            // In production, this would restore previous purchases
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: min(geometry.size.width * 0.035, 14), weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, geometry.size.height * 0.008)
                        
                        // Continue with Limited Version
                        Button(action: {
                            dismiss()
                        }) {
                            Text("No Thanks, Continue Limited")
                                .font(.system(size: min(geometry.size.width * 0.03, 12)))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, geometry.size.height * 0.01)
                        .padding(.bottom, geometry.size.height * 0.025)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height * 0.80)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
                .environmentObject(authService)
        }
    }
}

#Preview {
    NavigationView {
        PaywallView()
            .environmentObject(UserSettings())
    }
}

