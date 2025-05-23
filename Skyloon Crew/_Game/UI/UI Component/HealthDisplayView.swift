// SwiftUI_UI/HealthDisplayView.swift
import SwiftUI

struct HealthDisplayView: View {
    let currentHealth: Int
    let maxHealth: Int = 3 // Or make this configurable

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<maxHealth, id: \.self) { index in
                Image(systemName: index < currentHealth ? "heart.fill" : "heart")
                    .foregroundColor(index < currentHealth ? .red : .gray)
                    .font(.title2) // Adjust size as needed
            }
        }
    }
}

struct HealthDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            HealthDisplayView(currentHealth: 3)
            HealthDisplayView(currentHealth: 2)
            HealthDisplayView(currentHealth: 1)
            HealthDisplayView(currentHealth: 0)
        }
        .padding()
        .background(Color.black.opacity(0.1))
    }
}
