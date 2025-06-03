//
//  testingUI.swift
//  Skyloon Crew
//
//  Created by Bregas Satria Wicaksono on 03/06/25.
//

import SwiftUI

struct testingUI: View {
    var body: some View {
        Image("UI_Icon_AlarmOff")
            .colorMultiply(.green)
            .overlay{
                Image("UI_Icon_AlarmOff")
                    .colorMultiply(.brown)
                    .opacity(0.8)
            }
        
    }
}

#Preview {
    testingUI()
}
