//
//  ErrorView.swift
//  Challenge2
//
//  Created by Reza Juliandri on 19/05/25.
//


import SwiftUI

struct ErrorView: View {
    var message: String
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
                .lineLimit(2)
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(4)
    }
}