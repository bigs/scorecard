// Renders the Scorecard menu-bar template image and the macOS AppIcon set
// from a single SwiftUI shape. Run from the repo root:
//
//     xcrun -sdk macosx swift Scripts/generate_icons.swift
//
// Output:
//   Scorecard/Assets.xcassets/AppIcon.appiconset/icon_*.png
//   Scorecard/Assets.xcassets/MenuBarIcon.imageset/menubar*.png + Contents.json

import Foundation
import AppKit
import SwiftUI

// MARK: - Shape

/// Folded golf scorecard silhouette. Outer rounded rectangle with a vertical
/// fold line cut out down the middle. Uses even-odd fill to subtract the
/// fold from the body.
struct ScorecardSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cornerRadius = rect.width * 0.12

        // Outer card body.
        path.addRoundedRect(
            in: rect,
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )

        // Fold line down the middle.
        let foldWidth = rect.width * 0.06
        let foldInset = rect.height * 0.10
        path.addRect(CGRect(
            x: rect.midX - foldWidth / 2,
            y: rect.minY + foldInset,
            width: foldWidth,
            height: rect.height - foldInset * 2
        ))

        return path
    }
}

// MARK: - Views

struct MenuBarIconView: View {
    var body: some View {
        // Portrait card with breathing room top/bottom.
        ScorecardSilhouette()
            .fill(Color.black, style: FillStyle(eoFill: true))
            .aspectRatio(0.78, contentMode: .fit)
            .padding(.vertical, 1)
    }
}

struct AppIconView: View {
    let canvasSize: CGFloat

    var body: some View {
        ZStack {
            // Squircle background — Big Sur+ macOS icon shape.
            RoundedRectangle(cornerRadius: canvasSize * 0.225, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.96, green: 0.96, blue: 0.93),
                            Color(red: 0.86, green: 0.83, blue: 0.74),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Silhouette in deep golf-green.
            ScorecardSilhouette()
                .fill(
                    Color(red: 0.09, green: 0.26, blue: 0.16),
                    style: FillStyle(eoFill: true)
                )
                .aspectRatio(0.78, contentMode: .fit)
                .padding(canvasSize * 0.18)
        }
        .frame(width: canvasSize, height: canvasSize)
    }
}

// MARK: - Rendering

@MainActor
func renderPNG<Content: View>(_ view: Content, pixels: CGFloat) throws -> Data {
    let renderer = ImageRenderer(
        content: view.frame(width: pixels, height: pixels)
    )
    renderer.scale = 1.0
    guard let nsImage = renderer.nsImage,
          let tiff = nsImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "icon.render", code: 1, userInfo: [NSLocalizedDescriptionKey: "render failed"])
    }
    return png
}

// MARK: - Main

@MainActor
func main() async throws {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let assets = cwd.appendingPathComponent("Scorecard/Assets.xcassets")
    let appIconDir = assets.appendingPathComponent("AppIcon.appiconset")
    let menuBarDir = assets.appendingPathComponent("MenuBarIcon.imageset")

    try FileManager.default.createDirectory(at: menuBarDir, withIntermediateDirectories: true)

    // AppIcon: ten files spanning every macOS scale.
    let appSpecs: [(name: String, px: CGFloat)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024),
    ]

    for spec in appSpecs {
        let data = try renderPNG(AppIconView(canvasSize: spec.px), pixels: spec.px)
        try data.write(to: appIconDir.appendingPathComponent(spec.name))
        print("Wrote AppIcon \(spec.name) (\(Int(spec.px))px)")
    }

    // MenuBar imageset.
    let menuSpecs: [(name: String, px: CGFloat)] = [
        ("menubar.png", 22),
        ("menubar@2x.png", 44),
        ("menubar@3x.png", 66),
    ]
    for spec in menuSpecs {
        let data = try renderPNG(MenuBarIconView(), pixels: spec.px)
        try data.write(to: menuBarDir.appendingPathComponent(spec.name))
        print("Wrote MenuBar \(spec.name) (\(Int(spec.px))px)")
    }

    let menuContents = """
    {
      "images" : [
        { "idiom" : "mac", "filename" : "menubar.png", "scale" : "1x" },
        { "idiom" : "mac", "filename" : "menubar@2x.png", "scale" : "2x" },
        { "idiom" : "mac", "filename" : "menubar@3x.png", "scale" : "3x" }
      ],
      "info" : { "author" : "xcode", "version" : 1 },
      "properties" : { "template-rendering-intent" : "template" }
    }

    """
    try menuContents.write(
        to: menuBarDir.appendingPathComponent("Contents.json"),
        atomically: true,
        encoding: .utf8
    )
    print("Wrote MenuBarIcon Contents.json")

    print("Done.")
}

try await main()
