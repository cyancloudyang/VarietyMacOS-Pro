//
//  EdgeHaloModifier.swift
//  VarietyMacOS
//
//  Edge halo effect for Liquid Glass design language
//  Creates subtle glow from edges with breathing animation
//

import SwiftUI

// MARK: - Edge Halo Modifier

/// Edge halo effect following Liquid Glass design
struct EdgeHaloModifier: ViewModifier {
    let color: Color
    let intensity: CGFloat
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let blurRadius: CGFloat
    
    init(
        color: Color = .white,
        intensity: CGFloat = 1.0,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        blurRadius: CGFloat = 8
    ) {
        self.color = color
        self.intensity = min(max(intensity, 0), 1)
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.blurRadius = blurRadius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.5 * intensity),
                                color.opacity(0.2 * intensity),
                                color.opacity(0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth * 1.5
                    )
                    .blur(radius: blurRadius)
            )
    }
}

// MARK: - Animated Edge Halo Modifier

/// Edge halo with breathing animation (3 second cycle)
struct AnimatedEdgeHaloModifier: ViewModifier {
    let color: Color
    let intensity: CGFloat
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let blurRadius: CGFloat
    let animationDuration: Double
    
    @State private var phase: CGFloat = 0
    
    init(
        color: Color = .white,
        intensity: CGFloat = 1.0,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        blurRadius: CGFloat = 8,
        animationDuration: Double = 3.0
    ) {
        self.color = color
        self.intensity = min(max(intensity, 0), 1)
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.blurRadius = blurRadius
        self.animationDuration = animationDuration
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.5 * intensity * sin(phase)),
                                color.opacity(0.2 * intensity),
                                color.opacity(0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: lineWidth * 1.5
                    )
                    .blur(radius: blurRadius)
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                ) {
                    phase = .pi * 2
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Apply edge halo effect
    /// - Parameters:
    ///   - color: Halo color (default: white)
    ///   - intensity: Effect intensity 0.0-1.0 (default: 1.0)
    ///   - cornerRadius: Corner radius (default: 12)
    ///   - lineWidth: Stroke width (default: 2)
    ///   - blurRadius: Blur radius (default: 8)
    func edgeHalo(
        color: Color = .white,
        intensity: CGFloat = 1.0,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        blurRadius: CGFloat = 8
    ) -> some View {
        modifier(EdgeHaloModifier(
            color: color,
            intensity: intensity,
            cornerRadius: cornerRadius,
            lineWidth: lineWidth * 1.5,
            blurRadius: blurRadius
        ))
    }
    
    /// Apply animated edge halo with breathing effect
    /// - Parameters:
    ///   - color: Halo color (default: white)
    ///   - intensity: Effect intensity 0.0-1.0 (default: 1.0)
    ///   - cornerRadius: Corner radius (default: 12)
    ///   - lineWidth: Stroke width (default: 2)
    ///   - blurRadius: Blur radius (default: 8)
    ///   - animationDuration: Breathing cycle duration (default: 3.0 seconds)
    func animatedEdgeHalo(
        color: Color = .white,
        intensity: CGFloat = 1.0,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 2,
        blurRadius: CGFloat = 8,
        animationDuration: Double = 3.0
    ) -> some View {
        modifier(AnimatedEdgeHaloModifier(
            color: color,
            intensity: intensity,
            cornerRadius: cornerRadius,
            lineWidth: lineWidth * 1.5,
            blurRadius: blurRadius,
            animationDuration: animationDuration
        ))
    }
}
