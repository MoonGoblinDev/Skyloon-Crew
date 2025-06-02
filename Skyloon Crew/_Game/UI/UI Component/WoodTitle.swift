//
//  WoodTitle.swift
//  iCon
//
//  Created by Reza Juliandri on 30/05/25.
//
import SwiftUI

struct WoodTitle: View {
    var title: String
    var body: some View {
        VStack {
            Text.gameFont(title, fontSize: 24, stroke: .black, shadowColor: .brown)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(
                    Image("Banner_Wood")
                        .resizable(capInsets: EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                )
        }
        .padding(.horizontal, 30)
        .padding(.top, 15)
    }
}

#Preview {
    WoodTitle(title: "Lorem ipsum dolor sit amet")
}
