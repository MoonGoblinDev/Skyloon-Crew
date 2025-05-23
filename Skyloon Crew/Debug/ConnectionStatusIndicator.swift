//
//  ConnectionStatusIndicator.swift
//  Challenge2
//
//  Created by Reza Juliandri on 19/05/25.
//


import SwiftUI

struct ConnectionStatusIndicator: View {
    var state: ConnectionState
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(indicatorColor)
                .frame(width: 10, height: 10)
            
            Text(state.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(indicatorColor)
        }
    }
    
    private var indicatorColor: Color {
        switch state {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .gray
        }
    }
}