//
//  BarIndicator.swift
//  Challenge2
//
//  Created by Reza Juliandri on 19/05/25.
//


import SwiftUI

struct BarIndicator: View {
    var value: Double
    var label: String
    var color: Color
    var width: CGFloat
    var range: (min: Double, max: Double)? // Optional custom range for normalization

    private var normalizedValue: Double {
        let minVal = range?.min ?? -1.0 // Default range -1 to 1 if not specified
        let maxVal = range?.max ?? 1.0
        
        guard maxVal > minVal else { return 0.5 } // Avoid division by zero or invalid range, default to middle
        
        let clampedValue = max(minVal, min(value, maxVal)) // Clamp value to the defined range
        return (clampedValue - minVal) / (maxVal - minVal) // Normalize to 0-1 range
    }
    
    var body: some View {
        VStack(spacing: 1) { // Reduced spacing
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                        .frame(height: geometry.size.height)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(height: CGFloat(normalizedValue) * geometry.size.height)
                }
            }
            
            Text(label)
                .font(.system(size: 8)) // Smaller label
                .foregroundColor(color)
        }
        .frame(width: width)
    }
}
