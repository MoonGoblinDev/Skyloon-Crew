//
//  StatusIndicator.swift
//  Challenge2
//
//  Created by Reza Juliandri on 19/05/25.
//


import SwiftUI

struct StatusIndicator: View {
    var isActive: Bool
    var activeText: String
    var inactiveText: String
    var activeColor: Color = .green
    var inactiveColor: Color = .gray
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? activeColor : inactiveColor)
                .frame(width: 10, height: 10)
            
            Text(isActive ? activeText : inactiveText)
                .font(.subheadline)
        }
    }
}