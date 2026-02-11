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
    func extract(from artwork: Artwork?) async {
        guard let artwork else {
            hasExtracted = false
            withAnimation(.easeInOut(duration: 0.3)) {
                colors = (.white.opacity(0.6), .white.opacity(0.6))
            }
            return
        }

        guard let url = artwork.url(width: 40, height: 40) else { return }
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

        let sorted = buckets.sorted { $0.value > $1.value }

        guard let first = sorted.first else {
            return (.white.opacity(0.6), .white.opacity(0.6))
        }

        let color1 = color(from: first.key)

        // Find second color that's distinct enough from the first
        var color2 = color1
        for entry in sorted.dropFirst() {
            if colorDistance(first.key, entry.key) > 60 {
                color2 = color(from: entry.key)
                break
            }
        }

        // If no distinct second color, derive one by shifting brightness
        if sorted.count <= 1 || color2 == color1 {
            color2 = brightnessShifted(from: first.key)
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
