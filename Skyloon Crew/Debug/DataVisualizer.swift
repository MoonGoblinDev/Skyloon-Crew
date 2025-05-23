//
//  DataVisualizer.swift
//  Challenge2
//
//  Created by Reza Juliandri on 19/05/25.
//


import SwiftUI

struct DataVisualizer: View {
    var value1: Double
    var value2: Double
    var value3: Double
    var labels: (String, String, String)
    var colors: (Color, Color, Color)
    // Takes a tuple of ranges, one for each bar
    var ranges: ((min: Double, max: Double), (min: Double, max: Double), (min: Double, max: Double))?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                BarIndicator(value: value1, label: labels.0, color: colors.0, width: geometry.size.width / 3 - 2, range: ranges?.0)
                BarIndicator(value: value2, label: labels.1, color: colors.1, width: geometry.size.width / 3 - 2, range: ranges?.1)
                BarIndicator(value: value3, label: labels.2, color: colors.2, width: geometry.size.width / 3 - 2, range: ranges?.2)
            }
        }
    }
}