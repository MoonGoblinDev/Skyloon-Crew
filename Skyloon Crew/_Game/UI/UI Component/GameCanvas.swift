//
//  CanvasTest.swift
//  iCon
//
//  Created by Reza Juliandri on 30/05/25.
//
import SwiftUI

struct GameCanvas<ContentView: View>: View {
    var title: String?
    @ViewBuilder var content: () -> ContentView
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                VStack {
                    content()
                }
                .padding(40)
                .background(
                    ZStack {
                        Image("Panel_Window")
                            .fromAsset(allInsets: 32)
                        Image("Paper")
                            .fromAsset(allInsets: 32)
                            .padding(20)
                        
                    }
                   
                )
            }
            .padding(.top, 40)
            if let title {
                VStack {
                    WoodTitle(title: title)
                }
            }
            
            
        }
    }
}

#Preview {
    GameCanvas(title: "Hello World") {
        Text.gameFont("Hello world")
    }
}
