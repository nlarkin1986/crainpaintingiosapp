import SwiftUI

/// **Animation System for Apple Design Award-Level Polish**
/// Consistent, delightful animations throughout the app
/// Date: March 6, 2026

// MARK: - Animation Presets

extension Animation {
    /// Quick, responsive spring for button presses
    static let springFast = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Default spring for most UI transitions
    static let springDefault = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    /// Gentle spring for large elements
    static let springGentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    /// Bouncy spring for celebration moments
    static let springBouncy = Animation.interpolatingSpring(stiffness: 170, damping: 15)
    
    /// Smooth ease for fades
    static let smoothFade = Animation.easeInOut(duration: 0.25)
    
    /// Quick snap for immediate feedback
    static let snap = Animation.easeOut(duration: 0.15)
}

// MARK: - Enhanced Button Style with Press Animation

struct EnhancedButtonStyle: ButtonStyle {
    let scaleAmount: CGFloat
    let haptic: Bool
    
    init(scaleAmount: CGFloat = 0.97, haptic: Bool = true) {
        self.scaleAmount = scaleAmount
        self.haptic = haptic
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.springFast, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && haptic {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
    }
}

// MARK: - Shimmer Loading Effect

struct AnimatedShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                phase = 1.0
                            }
                        }
                    }
                }
            }
            .clipped()
    }
}

extension View {
    func shimmer(isActive: Bool) -> some View {
        modifier(AnimatedShimmerModifier(isActive: isActive))
    }
}

// MARK: - Staggered Appearance

struct StaggeredAppearanceModifier: ViewModifier {
    let index: Int
    let delay: Double
    @State private var isVisible = false
    
    init(index: Int, delay: Double = 0.05) {
        self.index = index
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.springGentle.delay(Double(index) * delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    func staggeredAppearance(index: Int, delay: Double = 0.05) -> some View {
        modifier(StaggeredAppearanceModifier(index: index, delay: delay))
    }
}

// MARK: - Bounce Effect

struct BounceModifier: ViewModifier {
    let trigger: Int
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _, _ in
                // Bounce animation sequence
                withAnimation(.springBouncy) {
                    scale = 1.15
                }
                withAnimation(.springBouncy.delay(0.15)) {
                    scale = 1.0
                }
            }
    }
}

extension View {
    func bounce(trigger: Int) -> some View {
        modifier(BounceModifier(trigger: trigger))
    }
}

// MARK: - Pulse Effect

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onChange(of: isActive) { _, active in
                if active {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.springFast) {
                        isPulsing = false
                    }
                }
            }
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
}

extension View {
    func pulse(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
}

// MARK: - Confetti Celebration

struct ConfettiView: View {
    let colors: [Color]
    let particleCount: Int
    @State private var animate = false
    
    init(
        colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink],
        particleCount: Int = 30
    ) {
        self.colors = colors
        self.particleCount = particleCount
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<particleCount, id: \.self) { index in
                    ConfettiParticle(
                        color: colors.randomElement() ?? .blue,
                        animate: animate,
                        delay: Double(index) * 0.02,
                        geometry: geometry
                    )
                }
            }
        }
        .onAppear {
            animate = true
        }
        .allowsHitTesting(false)
    }
}

private struct ConfettiParticle: View {
    let color: Color
    let animate: Bool
    let delay: Double
    let geometry: GeometryProxy
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0
    
    private var randomX: CGFloat {
        CGFloat.random(in: -150...150)
    }
    
    private var randomY: CGFloat {
        CGFloat.random(in: -300...(-50))
    }
    
    private var randomRotation: Double {
        Double.random(in: -360...360)
    }
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .easeOut(duration: 1.5).delay(delay)
                ) {
                    offsetX = randomX
                    offsetY = randomY
                    opacity = 0
                    rotation = randomRotation
                }
            }
    }
}

// MARK: - Success Checkmark Animation

struct AnimatedCheckmark: View {
    @State private var trimEnd: CGFloat = 0
    @State private var scale: CGFloat = 0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(ColorTokens.feedbackSuccess)
                .scaleEffect(scale)
            
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(scale)
        }
        .onAppear {
            withAnimation(.springBouncy.delay(0.1)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Heart Favorite Animation

struct AnimatedHeart: View {
    let isFavorite: Bool
    @State private var scale: CGFloat = 1.0
    @State private var particles: [HeartParticle] = []
    
    var body: some View {
        ZStack {
            // Main heart
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(isFavorite ? .red : .gray)
                .scaleEffect(scale)
            
            // Particles
            ForEach(particles) { particle in
                Circle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(x: particle.offsetX, y: particle.offsetY)
                    .opacity(particle.opacity)
            }
        }
        .onChange(of: isFavorite) { _, newValue in
            if newValue {
                // Bounce animation
                withAnimation(.springBouncy) {
                    scale = 1.3
                }
                withAnimation(.springBouncy.delay(0.15)) {
                    scale = 1.0
                }
                
                // Particle burst
                createParticles()
            } else {
                // Simple scale down
                withAnimation(.springFast) {
                    scale = 0.8
                }
                withAnimation(.springFast.delay(0.1)) {
                    scale = 1.0
                }
            }
        }
    }
    
    private func createParticles() {
        particles = (0..<8).map { index in
            let angle = Double(index) * 45.0
            let distance: CGFloat = 30
            let radians = angle * .pi / 180
            
            return HeartParticle(
                offsetX: distance * cos(radians),
                offsetY: distance * sin(radians),
                opacity: 0
            )
        }
        
        // Animate particles out
        withAnimation(.easeOut(duration: 0.5)) {
            particles = particles.map { particle in
                HeartParticle(
                    offsetX: particle.offsetX,
                    offsetY: particle.offsetY,
                    opacity: 0
                )
            }
        }
        
        // Clear particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            particles = []
        }
    }
}

private struct HeartParticle: Identifiable {
    let id = UUID()
    let offsetX: CGFloat
    let offsetY: CGFloat
    let opacity: Double
}

// MARK: - Loading Dots

struct LoadingDotsView: View {
    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false
    
    let color: Color
    
    init(color: Color = ColorTokens.aqua) {
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(animatingDot1 ? 1 : 0.3)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(animatingDot2 ? 1 : 0.3)
            
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .opacity(animatingDot3 ? 1 : 0.3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                animatingDot1 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.2)) {
                animatingDot2 = true
            }
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(0.4)) {
                animatingDot3 = true
            }
        }
    }
}

// MARK: - Ripple Effect

struct RippleEffect: View {
    @State private var ripples: [Ripple] = []
    let color: Color
    
    init(color: Color) {
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(ripples) { ripple in
                    Circle()
                        .stroke(color.opacity(ripple.opacity), lineWidth: 2)
                        .frame(width: ripple.scale * geometry.size.width,
                               height: ripple.scale * geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        }
        .onAppear {
            startRipple()
        }
    }
    
    private func startRipple() {
        let ripple = Ripple(scale: 0, opacity: 0.8)
        ripples.append(ripple)
        
        withAnimation(.easeOut(duration: 1.0)) {
            if let index = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[index].scale = 1.0
                ripples[index].opacity = 0
            }
        }
        
        // Remove ripple after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}

private struct Ripple: Identifiable {
    let id = UUID()
    var scale: CGFloat
    var opacity: Double
}

// MARK: - Page Transition

struct PageTransition: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .scaleEffect(isActive ? 1 : 0.95)
            .animation(.springDefault, value: isActive)
    }
}

extension View {
    func pageTransition(isActive: Bool) -> some View {
        modifier(PageTransition(isActive: isActive))
    }
}
