//
//  Untitled.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//

import SwiftUI

struct HandMotionView: View {
    let flip: Bool = false
    @State private var offset: CGSize = .zero
    
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 300, height: 300)
                                .overlay{
                                    Image("ArrowMotion")
                                        .resizable()
                                        .frame(width: 512, height: 512)

                                    Image("Motion Hand")
                                        .resizable()
                                        .frame(width: 512, height: 512)
                                        .offset(offset)
                                        .onAppear {
                                            withAnimation(
                                                .easeInOut(duration: 1.5)
                                                .repeatForever(autoreverses: true)
                                            ) {
                                                offset = CGSize(width: -110, height: 100)
                                            }
                                        }
                                }
                                .clipped()
                                .scaleEffect(x: flip ? -1 : 1, y: 1)
        }
        
        
    }
}

#Preview {
    HandMotionView().frame(width: 800, height: 800)
}
