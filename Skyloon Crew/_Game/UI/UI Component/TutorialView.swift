//
//  Tutorial.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//

import SwiftUI

struct TutorialView: View {
    var body: some View {
        VStack {
            Text.gameFont("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam")
                .padding()
        }
        .frame(maxWidth: 800, maxHeight: 200)
        .background(
            Image("UI_Bar")
                .resizable(
                    capInsets: EdgeInsets(top: 29, leading: 29, bottom: 29, trailing: 29),
                    resizingMode: .stretch
                )
                
        )
        
            }
}


#Preview {
    TutorialView().frame(width: 1200, height: 800)
}

