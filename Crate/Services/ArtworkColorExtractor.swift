import SwiftUI
import MusicKit
import ImageIO
import CoreGraphics

/// Extracts the two most prominent colors from MusicKit Artwork
/// using CoreGraphics pixel sampling. Results are cached by URL.
@Observable
@MainActor
final class ArtworkColorExtractor {

    /// The two most prominent colors from the current artwork.
    var colors: (Color, Color) = (.white.opacity(0.6), .white.opacity(0.6))

    /// Whether colors have been extracted (vs. still using fallback).
    var hasExtracted = false

    private var cache: [String: (Color, Color)] = [:]

    /// Extract dominant colors from the given artwork.
    /// Call this from `.task(id:)` so it cancels on artwork change.
    ///
    /// When `artwork` is nil (common for chart-sourced albums), falls back
    /// to `artworkURL` (the `{w}x{h}` template string from the API).
    func extract(from artwork: Artwork?, artworkURL: String? = nil) async {
        // Resolve a concrete URL from either source.
        let resolvedURL: URL? = {
            if let artwork {
                return artwork.url(width: 40, height: 40)
            }
            if let template = artworkURL {
                let filled = template
                    .replacingOccurrences(of: "{w}", with: "40")
                    .replacingOccurrences(of: "{h}", with: "40")
                return URL(string: filled)
            }
            return nil
        }()

        guard let url = resolvedURL else {
            hasExtracted = false
            withAnimation(.easeInOut(duration: 0.3)) {
                colors = (.white.opacity(0.6), .white.opacity(0.6))
            }
            return
        }

        let key = url.absoluteString

        // Check cache first
        if let cached = cache[key] {
            withAnimation(.easeInOut(duration: 0.3)) {
                colors = cached
                hasExtracted = true
            }
            return
        }

        // Download and extract off-main
        do {
            let extracted = try await Self.extractColors(from: url)
            cache[key] = extracted
            withAnimation(.easeInOut(duration: 0.3)) {
                colors = extracted
                hasExtracted = true
            }
        } catch {
            print("[Crate] ArtworkColorExtractor failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private

    /// Downloads a small artwork image and extracts the two most prominent colors.
    private static func extractColors(from url: URL) async throws -> (Color, Color) {
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ExtractionError.invalidImage
        }

        // Downsample to 10x10 for fast pixel analysis
        let size = 10
        let totalPixels = size * size
        let bytesPerPixel = 4
        let bytesPerRow = size * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: totalPixels * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ExtractionError.contextCreationFailed
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        // Bucket pixels by quantized RGB (nearest 32 per channel)
        var buckets: [[UInt8]: Int] = [:]
        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            let r = pixelData[offset]
            let g = pixelData[offset + 1]
            let b = pixelData[offset + 2]
            let a = pixelData[offset + 3]

            // Skip nearly transparent pixels
            guard a > 128 else { continue }

            let qr = (r / 32) * 32
            let qg = (g / 32) * 32
            let qb = (b / 32) * 32
            let key: [UInt8] = [qr, qg, qb]
            buckets[key, default: 0] += 1
        }

        // Score each bucket: frequency × saturation³ × brightness floor.
        // Saturation is cubed so it dominates — a pastel at 50% of pixels
        // loses to a vivid color at 10%. Near-blacks and desaturated colors
        // (whites, grays, pastels) are filtered out entirely.
        let scored: [([UInt8], Double)] = buckets.compactMap { key, count in
            let hsb = rgbToHSB(key)

            // Hard filter: too dark or too desaturated
            if hsb.brightness < 0.12 { return nil }
            if hsb.saturation < 0.15 { return nil }

            let frequency = Double(count)
            // Saturation cubed: 0.2 → 0.008, 0.5 → 0.125, 1.0 → 1.0
            let saturationWeight = hsb.saturation * hsb.saturation * hsb.saturation
            // Brightness floor: ramps to 1.0 at brightness 0.4+, penalizes very dark
            let brightnessWeight = min(hsb.brightness / 0.4, 1.0)
            let score = frequency * saturationWeight * brightnessWeight
            return (key, score)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }

        // If all buckets were filtered out, fall back to raw frequency
        let fallbackSorted = buckets.sorted { $0.value > $1.value }
        let primary = sorted.first?.0 ?? fallbackSorted.first?.key

        guard let firstKey = primary else {
            return (.white.opacity(0.6), .white.opacity(0.6))
        }

        let color1 = color(from: firstKey)

        // Find second color that's distinct enough from the first
        var color2 = color1
        for (key, _) in sorted.dropFirst() {
            if colorDistance(firstKey, key) > 60 {
                color2 = color(from: key)
                break
            }
        }

        // If no distinct second color, derive one by shifting brightness
        if sorted.count <= 1 || color2 == color1 {
            color2 = brightnessShifted(from: firstKey)
        }

        return (color1, color2)
    }

    private static func color(from rgb: [UInt8]) -> Color {
        Color(
            red: Double(rgb[0]) / 255.0,
            green: Double(rgb[1]) / 255.0,
            blue: Double(rgb[2]) / 255.0
        )
    }

    private static func colorDistance(_ a: [UInt8], _ b: [UInt8]) -> Double {
        let dr = Double(a[0]) - Double(b[0])
        let dg = Double(a[1]) - Double(b[1])
        let db = Double(a[2]) - Double(b[2])
        return (dr * dr + dg * dg + db * db).squareRoot()
    }

    private static func rgbToHSB(_ rgb: [UInt8]) -> (hue: Double, saturation: Double, brightness: Double) {
        let r = Double(rgb[0]) / 255.0
        let g = Double(rgb[1]) / 255.0
        let b = Double(rgb[2]) / 255.0
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        let brightness = maxC
        let saturation = maxC == 0 ? 0 : delta / maxC

        var hue: Double = 0
        if delta > 0 {
            if maxC == r {
                hue = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                hue = (b - r) / delta + 2
            } else {
                hue = (r - g) / delta + 4
            }
            hue /= 6
            if hue < 0 { hue += 1 }
        }

        return (hue, saturation, brightness)
    }

    private static func brightnessShifted(from rgb: [UInt8]) -> Color {
        let brightness = (Double(rgb[0]) + Double(rgb[1]) + Double(rgb[2])) / 3.0
        let factor: Double = brightness > 128 ? 0.6 : 1.5
        return Color(
            red: min(Double(rgb[0]) * factor / 255.0, 1.0),
            green: min(Double(rgb[1]) * factor / 255.0, 1.0),
            blue: min(Double(rgb[2]) * factor / 255.0, 1.0)
        )
    }

    private enum ExtractionError: Error, LocalizedError {
        case invalidImage
        case contextCreationFailed

        var errorDescription: String? {
            switch self {
            case .invalidImage: return "Could not decode artwork image"
            case .contextCreationFailed: return "Could not create graphics context"
            }
        }
    }
}
