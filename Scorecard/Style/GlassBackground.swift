import SwiftUI

/// The corner radius used everywhere the panel's outer shape is needed.
let panelCornerRadius: CGFloat = 16

/// Shape used as the panel's outer rounded rectangle. Centralised so the
/// glass surface, the clip, and the edge highlight all agree.
var panelShape: RoundedRectangle {
    RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
}

/// Hairline rim around the glass surface plus a faint inner top highlight.
/// Together these read as the curvature of a lens — the bit that makes
/// Liquid Glass feel like glass instead of a flat fill.
struct GlassEdgeHighlight: View {
    var body: some View {
        ZStack {
            // Outer rim: brighter on top (specular), darker on bottom (shadow).
            panelShape
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.65),
                            Color.white.opacity(0.10),
                            Color.black.opacity(0.06),
                            Color.black.opacity(0.18),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.75
                )
            // Inner top sheen — a soft falloff that mimics light catching the
            // upper curve of the lens. Drawn at very low opacity so it reads
            // without dominating.
            panelShape
                .inset(by: 0.5)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), .clear],
                        startPoint: .top,
                        endPoint: .center
                    ),
                    lineWidth: 1
                )
                .blendMode(.plusLighter)
                .blur(radius: 0.6)
        }
        .allowsHitTesting(false)
    }
}
