//
// LiquidGlassBackground.swift
// VarietyMacOS
//
// Liquid Glass background effect with three-layer structure:
// 1. Liquid Layer - base color with flowing animation
// 2. Refraction Layer - multi-blur simulation for glass refraction
// 3. Edge Halo Layer - subtle glow from edges
//

import SwiftUI
import CoreImage

// MARK: - Liquid Glass Background

/// Liquid Glass background effect following Apple's Liquid Glass design language
struct LiquidGlassBackground: View {
    let wallpaper: Wallpaper?
    let intensity: CGFloat
    let scrollOffset: CGFloat
    let isAnimating: Bool
    
    @State private var dominantColor: Color = .clear
    @State private var edgeColor: Color = .clear
    @State private var cachedImage: NSImage?
    
    private let flowAnimationDuration = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Liquid Layer - base color with flowing effect
                LiquidLayer(
                    color: dominantColor,
                    intensity: intensity,
                    scrollOffset: scrollOffset,
                    isAnimating: isAnimating,
                    animationDuration: flowAnimationDuration
                )
                
                // 2. Refraction Layer - multi-blur for glass effect
                if let wallpaper = wallpaper, let image = cachedImage {
                    RefractionLayer(
                        image: image,
                        intensity: intensity
                    )
                }
                
                // 3. Edge Halo Layer - subtle glow
                EdgeHaloLayer(
                    color: edgeColor,
                    intensity: intensity
                )
            }
            .blur(radius: 60 * (1.0 - intensity))
        }
        .onAppear {
            loadAndExtractColors()
        }
        .onChange(of: wallpaper) { _, _ in
            loadAndExtractColors()
        }
    }
    
    private func loadAndExtractColors() {
        guard let wallpaper = wallpaper else {
            dominantColor = .clear
            edgeColor = .clear
            cachedImage = nil
            return
        }
        
        // Use cached image if available
        if let image = wallpaper.cachedImage {
            cachedImage = image
            extractColors(from: image)
            return
        }
        
        // Load asynchronously
        Task {
            do {
                let image = try await wallpaper.loadImage()
                cachedImage = image
                extractColors(from: image)
            } catch {
                dominantColor = .clear
                edgeColor = .clear
            }
        }
    }
    
    private func extractColors(from image: NSImage) {
        let extractor = LiquidColorExtractor()
        dominantColor = Color(extractor.extractDominantColor(from: image))
        edgeColor = Color(extractor.extractEdgeColor(from: image))
    }
}

// MARK: - Liquid Layer

/// Base liquid layer with radial radiation from right edge
struct LiquidLayer: View {
  let color: Color
  let intensity: CGFloat
  let scrollOffset: CGFloat
  let isAnimating: Bool
  let animationDuration: Double
  
  @State private var animationOffset: CGFloat = 0
  
  var body: some View {
    ZStack {
      RadialGradient(
        colors: [
          color.opacity(0.4 * intensity),
          color.opacity(0.2 * intensity),
          color.opacity(0.1 * intensity),
          color.opacity(0.05 * intensity)
        ],
        center: .trailing,
        startRadius: 100,
        endRadius: 600
      )
      
      if isAnimating {
        FlowingGradient(offset: animationOffset, scrollOffset: scrollOffset)
          .opacity(0.3 * intensity)
      }
    }
    .animation(.linear(duration: animationDuration).repeatForever(autoreverses: true), value: isAnimating)
    .onAppear {
      if isAnimating {
        animationOffset = 1
      }
    }
  }
}

/// Flowing gradient animation
struct FlowingGradient: View {
    let offset: CGFloat
    let scrollOffset: CGFloat
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.1),
                Color.white.opacity(0.05),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .offset(y: offset * 100 - scrollOffset * 0.3)
        .blur(radius: 20)
    }
}

// MARK: - Refraction Layer

/// Multi-blur refraction layer simulating glass
struct RefractionLayer: View {
    let image: NSImage
    let intensity: CGFloat
    
    var body: some View {
        ZStack {
            // First blur layer (40px)
            Image(nsImage: image)
                .blur(radius: 40 * intensity)
                .opacity(0.6)
            
            // Second blur layer (20px) for depth
            Image(nsImage: image)
                .blur(radius: 20 * intensity)
                .opacity(0.4)
        }
        .blur(radius: 60 * (1.0 - intensity))
        .brightness(0.15 * intensity)
        .contrast(1.1 * intensity)
    }
}

// MARK: - Edge Halo Layer

/// Edge glow effect following Liquid Glass design
struct EdgeHaloLayer: View {
    let color: Color
    let intensity: CGFloat
    
    var body: some View {
        ZStack {
                // Top-left corner glow
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.6 * intensity),
                                color.opacity(0.3 * intensity),
                                .clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        ),
                        lineWidth: 3
                    )
                    .blur(radius: 12 * intensity)
                
                // Bottom-right corner glow (subtle)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3 * intensity),
                                .clear
                            ],
                            startPoint: .bottomTrailing,
                            endPoint: .center
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 8 * intensity)
            }
    }
}

// MARK: - Preview

#if DEBUG
struct LiquidGlassBackground_Previews: PreviewProvider {
    static var previews: some View {
        LiquidGlassBackground(
            wallpaper: nil,
            intensity: 0.8,
            scrollOffset: 0,
            isAnimating: true
        )
        .frame(width: 400, height: 600)
    }
}
#endif
