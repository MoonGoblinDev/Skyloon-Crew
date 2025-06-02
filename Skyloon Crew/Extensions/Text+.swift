//
//  Text+.swift
//  iCon
//
//  Created by Reza Juliandri on 30/05/25.
//
import SwiftUI

extension Text {
    static func gameFont(_ text: String,  fontSize: CGFloat = 24, stroke: Color = .clear, shadowColor: Color = .clear) -> some View {
        ZStack {
            // Shadow/outline text (background)
            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(shadowColor)
                .lineSpacing(4)
                .offset(x: 2, y: 2)
            
            // Main text (foreground)
            Text(text)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineSpacing(4)
                .strokeOutline(color: stroke)
        }
    }
}
