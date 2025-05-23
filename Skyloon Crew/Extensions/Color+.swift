//
//  Color+.swift
//  iCon
//
//  Created by Reza Juliandri on 22/05/25.
//
import SwiftUI
import AppKit // Import AppKit for NSColor

extension Color {
    // Convert Color to Hex String
    func toHex() -> String {
        // Use NSColor for macOS
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB),
              let components = nsColor.cgColor.components, components.count >= 3 else {
            // If the color can't be converted to sRGB (e.g., a pattern color),
            // try to get components directly. This might be less accurate for some color spaces.
            if let directComponents = NSColor(self).cgColor.components, directComponents.count >= 3 {
                let r = Int(directComponents[0] * 255)
                let g = Int(directComponents[1] * 255)
                let b = Int(directComponents[2] * 255)
                var a = 255

                if directComponents.count >= 4 {
                    a = Int(directComponents[3] * 255)
                }

                if a == 255 {
                    return String(format: "#%02X%02X%02X", r, g, b)
                } else {
                    return String(format: "#%02X%02X%02X%02X", r, g, b, a)
                }
            }
            return "#000000" // Default to black if components can't be read
        }

        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        var a = 255 // Default alpha to fully opaque

        if components.count >= 4 {
            a = Int(components[3] * 255)
        }

        if a == 255 { // Don't include alpha if fully opaque for shorter hex
            return String(format: "#%02X%02X%02X", r, g, b)
        } else {
            return String(format: "#%02X%02X%02X%02X", r, g, b, a)
        }
    }

    // Initialize Color from Hex String
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0 // Default alpha

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 { // RRGGBB
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 { // RRGGBBAA
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil // Invalid hex length
        }
        self.init(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
