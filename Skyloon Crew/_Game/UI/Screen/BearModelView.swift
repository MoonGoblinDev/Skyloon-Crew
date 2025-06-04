//
//  BearModelView.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//

import SwiftUI

struct BearModelView: View {
    let character: String
    
    init(character: String) {
        self.character = character
    }
    
    var body: some View {
        Image(character) // Uses the character string as the image name
            .resizable()
            .scaledToFit()
            .background(Color.clear)
    }
}

#Preview {
    BearModelView(character: "Panda")
        .frame(width: 200, height: 200)
}
