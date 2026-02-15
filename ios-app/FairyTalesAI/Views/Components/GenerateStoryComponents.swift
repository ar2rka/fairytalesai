import SwiftUI

// MARK: - Magic generating content (shared with HomeView Continue button)

struct MagicGeneratingRow: View {
    /// One phrase per generation: set when row appears, never change during this generation.
    @State private var phrase: String = ""
    var textSize: CGFloat = 18

    private var phrases: [String] {
        LocalizationManager.shared.generateStoryMagicPhrases
    }

    var body: some View {
        HStack {
            MagicGeneratingIcon()
            Text(phrase.isEmpty ? LocalizationManager.shared.generateStoryGenerating : phrase)
                .font(.system(size: textSize, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .onAppear {
            phrase = phrases.randomElement() ?? LocalizationManager.shared.generateStoryGenerating
        }
    }
}

struct MagicGeneratingIcon: View {
    var body: some View {
        Image(systemName: "wand.and.stars")
            .font(.system(size: 20, weight: .bold))
    }
}

// MARK: - Shimmering full-screen gradient background (e.g. StoryGeneratingView)
struct ShimmeringGradientBackground: View {
    var colorScheme: ColorScheme?
    @State private var startTime = Date()
    
    private var isDark: Bool {
        colorScheme != .light
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
            shimmeringGradient(now: context.date)
        }
        .onAppear {
            startTime = Date()
        }
    }
    
    private func shimmeringGradient(now: Date) -> some View {
        let elapsed = now.timeIntervalSince(startTime)
        let t = CGFloat((elapsed / 3.0).truncatingRemainder(dividingBy: 1.0))
        let t2 = CGFloat((elapsed / 4.2).truncatingRemainder(dividingBy: 1.0))
        let angle = Angle.degrees(elapsed * 36.0)
        
        let startA = UnitPoint(x: -0.2 + 1.4 * t, y: 0.0)
        let endA = UnitPoint(x: 1.2 - 1.4 * t, y: 1.0)
        let startB = UnitPoint(x: 1.0 - 1.2 * t2, y: 0.3)
        let endB = UnitPoint(x: 0.0 + 1.2 * t2, y: 0.7)
        
        let baseColor = isDark ? AppTheme.darkPurple : AppTheme.lightPurple
        let layerOpacity: Double = isDark ? 0.5 : 0.35
        
        return ZStack {
            baseColor
            
            LinearGradient(
                colors: [
                    AppTheme.primaryPurple.opacity(layerOpacity),
                    AppTheme.accentPurple.opacity(layerOpacity * 0.8),
                    AppTheme.pastelBlue.opacity(layerOpacity * 0.6),
                    AppTheme.pastelPink.opacity(layerOpacity * 0.5),
                    AppTheme.primaryPurple.opacity(layerOpacity)
                ],
                startPoint: startA,
                endPoint: endA
            )
            
            LinearGradient(
                colors: [
                    AppTheme.pastelBlue.opacity(0),
                    AppTheme.pastelBlue.opacity(layerOpacity * 0.4),
                    AppTheme.primaryPurple.opacity(0)
                ],
                startPoint: startB,
                endPoint: endB
            )
            
            AngularGradient(
                gradient: Gradient(colors: [
                    AppTheme.primaryPurple.opacity(layerOpacity * 0.3),
                    AppTheme.pastelPink.opacity(layerOpacity * 0.25),
                    AppTheme.accentPurple.opacity(layerOpacity * 0.3),
                    AppTheme.primaryPurple.opacity(layerOpacity * 0.3)
                ]),
                center: .center,
                angle: angle
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Generate button background: static purple + conditional shimmer while generating
struct GenerateButtonBackground: View {
    @Binding var isGenerating: Bool
    let isEnabled: Bool
    @State private var shimmerStartTime = Date()
    
    private static let violetA = Color(red: 0x66 / 255, green: 0x7e / 255, blue: 0xea / 255)
    private static let violetB = Color(red: 0x76 / 255, green: 0x4b / 255, blue: 0xa2 / 255)
    private static let violetC = Color(red: 0xf0 / 255, green: 0x93 / 255, blue: 0xfb / 255)
    private static let auroraCyan = Color(red: 0x48 / 255, green: 0xd9 / 255, blue: 0xff / 255)
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.primaryPurple, AppTheme.accentPurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isEnabled || isGenerating ? 1.0 : 0.6)
                
                if isGenerating {
                    TimelineView(.animation(minimumInterval: 1.0 / 45.0, paused: !isGenerating)) { context in
                        auroraShimmerOverlay(size: proxy.size, now: context.date)
                    }
                    .transition(.opacity)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .onChange(of: isGenerating) { _, newValue in
            if newValue {
                shimmerStartTime = Date()
            }
        }
        .animation(.easeInOut(duration: 0.28), value: isGenerating)
    }
    
    private func auroraShimmerOverlay(size: CGSize, now: Date) -> some View {
        let elapsed = now.timeIntervalSince(shimmerStartTime)
        _ = size
        
        let sweep = CGFloat((elapsed / 2.1).truncatingRemainder(dividingBy: 1.0))
        let sweep2 = CGFloat((elapsed / 3.4).truncatingRemainder(dividingBy: 1.0))
        
        let startA = UnitPoint(x: -1.0 + 2.0 * sweep, y: 0.0)
        let endA = UnitPoint(x: 0.6 + 2.0 * sweep, y: 1.0)
        let startB = UnitPoint(x: 1.2 - 2.0 * sweep2, y: 0.2)
        let endB = UnitPoint(x: -0.4 - 2.0 * sweep2, y: 0.9)
        let swirl = Angle.degrees(elapsed * 24.0)
        
        return ZStack {
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Self.violetA.opacity(0.42),
                            Self.violetB.opacity(0.28),
                            Self.violetC.opacity(0.46),
                            Self.violetB.opacity(0.32),
                            Self.violetA.opacity(0.42)
                        ],
                        startPoint: startA,
                        endPoint: endA
                    )
                )
            
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Self.auroraCyan.opacity(0.22),
                            Self.violetC.opacity(0.32),
                            Self.violetA.opacity(0.18),
                            Self.auroraCyan.opacity(0.22)
                        ]),
                        center: .center,
                        angle: swirl
                    )
                )
            
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Self.auroraCyan.opacity(0.0),
                            Self.auroraCyan.opacity(0.28),
                            Self.violetC.opacity(0.0)
                        ],
                        startPoint: startB,
                        endPoint: endB
                    )
                )
        }
        .opacity(0.92)
        .blendMode(.plusLighter)
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}
