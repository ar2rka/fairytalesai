import SwiftUI

struct StarParticleAnimation: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var opacity: Double = 1.0
    }
    
    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "sparkle")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                    .opacity(particle.opacity)
                    .position(particle.position)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        particles = (0..<20).map { _ in
            Particle(
                position: CGPoint(
                    x: centerX + CGFloat.random(in: -100...100),
                    y: centerY + CGFloat.random(in: -100...100)
                )
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                particles[i].position = CGPoint(
                    x: particles[i].position.x + CGFloat.random(in: -150...150),
                    y: particles[i].position.y + CGFloat.random(in: -150...150)
                )
                particles[i].opacity = 0
            }
        }
    }
}
