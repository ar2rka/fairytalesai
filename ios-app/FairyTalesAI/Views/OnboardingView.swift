import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var userSettings: UserSettings
    @State private var isPulsing = false
    @State private var showLimitedVersion = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient Background
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
                    // Top Animation Area (Dynamic sizing - ~25% of screen)
                    ZStack {
                        // Glowing sparkles effect
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.12, weight: .light))
                            .foregroundColor(.white.opacity(0.3))
                            .blur(radius: 20)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.10, weight: .medium))
                            .foregroundColor(.yellow.opacity(0.8))
                            .symbolEffect(.pulse, options: .repeating)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: geometry.size.height * 0.08, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(height: geometry.size.height * 0.25)
                    .frame(maxWidth: .infinity)
                    
                    // Content Section (Dynamic sizing - fills remaining space)
                    VStack(alignment: .center, spacing: geometry.size.height * 0.015) {
                        // Headline
                        Text("Magic Bedtimes, Every Night.")
                            .font(.system(size: min(geometry.size.width * 0.08, 32), weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .padding(.horizontal, geometry.size.width * 0.08)
                            .padding(.top, geometry.size.height * 0.02)
                        
                        // Subheadline
                        Text("Create personalized adventures where your child is the hero. Narrated by AI, tailored by you.")
                            .font(.system(size: min(geometry.size.width * 0.04, 16), weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(4)
                            .padding(.horizontal, geometry.size.width * 0.08)
                            .padding(.top, geometry.size.height * 0.01)
                        
                        // Features List (Dynamic spacing)
                        VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
                            FeatureRow(
                                icon: "wand.and.stars",
                                text: "Unlimited stories for any interest"
                            )
                            
                            FeatureRow(
                                icon: "speaker.wave.2.fill",
                                text: "Magical AI-narrated audio"
                            )
                            
                            FeatureRow(
                                icon: "clock.fill",
                                text: "Stories timed perfectly (3–30 mins)"
                            )
                        }
                        .padding(.horizontal, geometry.size.width * 0.08)
                        .padding(.top, geometry.size.height * 0.015)
                        
                        Spacer()
                        
                        // Primary CTA Button
                        Button(action: {
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            // Start free trial
                            userSettings.startFreeTrial()
                        }) {
                            HStack {
                                Text("Start Your 7-Day Free Trial")
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
                            // Restore purchases or view plans
                            // In production, this would open subscription management
                        }) {
                            Text("Restore Purchases")
                                .font(.system(size: min(geometry.size.width * 0.035, 14), weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, geometry.size.height * 0.008)
                        
                        // Continue with Limited Version - Simple text link at bottom
                        Button(action: {
                            userSettings.completeOnboarding()
                        }) {
                            Text("Continue with Limited Version")
                                .font(.system(size: min(geometry.size.width * 0.03, 12)))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, geometry.size.height * 0.01)
                        .padding(.bottom, geometry.size.height * 0.025)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geometry.size.height * 0.75)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(AppTheme.primaryPurple)
                .frame(width: 32)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserSettings())
}
