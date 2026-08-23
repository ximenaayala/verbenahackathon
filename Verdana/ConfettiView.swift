//
//  ConfettiView.swift
//  Verdana
//
//  Created by Ivanna Torres Mora on 23/08/26.
//
import SwiftUI

/// Confeti simple: partículas que caen y rotan una sola vez al aparecer.
/// Uso: superpón `ConfettiView()` con un `.overlay` o dentro de un `ZStack`,
/// controlado por un `@State` booleano que actives al mostrar la celebración.
struct ConfettiView: View {
    private let colors: [Color] = [
        Color(red: 0.11, green: 0.62, blue: 0.46), // brandGreen
        Color(red: 0.98, green: 0.65, blue: 0.20), // amber
        Color(red: 0.16, green: 0.47, blue: 0.85), // blue
        Color(red: 0.92, green: 0.35, blue: 0.45), // pink
        Color(red: 0.95, green: 0.82, blue: 0.25)  // yellow
    ]

    private let pieceCount = 60
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<pieceCount, id: \.self) { i in
                    ConfettiPiece(
                        color: colors[i % colors.count],
                        startX: CGFloat.random(in: 0...geo.size.width),
                        size: CGFloat.random(in: 6...11),
                        delay: Double.random(in: 0...0.25),
                        duration: Double.random(in: 1.4...2.2),
                        travel: geo.size.height * 0.75,
                        rotation: Double.random(in: 180...720),
                        animate: animate
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}

private struct ConfettiPiece: View {
    let color: Color
    let startX: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double
    let travel: CGFloat
    let rotation: Double
    let animate: Bool

    @State private var offsetY: CGFloat = -20
    @State private var opacity: Double = 1
    @State private var angle: Double = 0

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size * 0.4)
            .rotationEffect(.degrees(angle))
            .position(x: startX, y: offsetY)
            .opacity(opacity)
            .onChange(of: animate) { _, newValue in
                guard newValue else { return }
                withAnimation(.easeIn(duration: duration).delay(delay)) {
                    offsetY = travel
                    angle = rotation
                }
                withAnimation(.easeIn(duration: 0.4).delay(delay + duration - 0.4)) {
                    opacity = 0
                }
            }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        ConfettiView()
    }
}

