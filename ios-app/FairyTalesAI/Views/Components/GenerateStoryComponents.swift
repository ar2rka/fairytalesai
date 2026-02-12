import SwiftUI

// MARK: - Magic generating content (shared with HomeView Continue button)

struct MagicGeneratingRow: View {
    /// One phrase per generation: set when row appears, never change during this generation.
    @State private var phrase: String = ""

    private var phrases: [String] {
        LocalizationManager.shared.generateStoryMagicPhrases
    }

    var body: some View {
        HStack {
            MagicGeneratingIcon()
            Text(phrase.isEmpty ? LocalizationManager.shared.generateStoryGenerating : phrase)
                .font(.system(size: 18, weight: .bold))
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
