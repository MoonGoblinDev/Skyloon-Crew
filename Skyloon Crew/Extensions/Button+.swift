//
//  Button+.swift
//  iCon
//
//  Created by Reza Juliandri on 21/05/25.
//

import SwiftUI

extension Button {
    
}

enum GameButtonState{
    case green
    case red
    case grey
    case orange
    case blue
}

struct GameButton<Label: View>: View {
    let action: () -> Void
    let isDisabled: Bool
    let label: () -> Label
    let state: GameButtonState

    init(
        state: GameButtonState = GameButtonState.green,
        disabled: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.state = state
        self.action = action
        self.label = label
        self.isDisabled = disabled
    }

    var body: some View {
        Button(action: action, label: label)
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .background {
                getButtonImage
            }
            .disabled(isDisabled)
    }
    
    var getButtonImage: some View {
        switch state {
        case .green:
            return Image("Button_Green").fromAsset()
        case .orange:
            return Image("Button_Orange").fromAsset()
        case .red:
            return Image("Button_Red").fromAsset()
        case .grey:
            return Image("Button_Grey").fromAsset()
        case .blue:
            return Image("Button_Blue").fromAsset()
        }
    }
}


struct CustomizableButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var borderColor: Color? = nil
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(16 / 1.5) // Consider making padding configurable too
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(10)
            .overlay(
                Group { // Use Group to conditionally apply the overlay
                    if let borderColor = borderColor {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(configuration.isPressed ? pressedScale : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }
}
// Define your specific styles using this customizable style
extension ButtonStyle where Self == CustomizableButtonStyle {
    static var primary: CustomizableButtonStyle {
        CustomizableButtonStyle(backgroundColor: .blue, foregroundColor: .white)
    }

    static var secondary: CustomizableButtonStyle {
        CustomizableButtonStyle(
            backgroundColor: Color(nsColor: NSColor.windowBackgroundColor),
            foregroundColor: .blue,
            borderColor: .blue
        )
    }

    static var destructive: CustomizableButtonStyle {
        CustomizableButtonStyle(backgroundColor: .red, foregroundColor: .white)
    }

    // Example of a slightly different common style
    static func common(bgColor: Color, fgColor: Color) -> CustomizableButtonStyle {
        CustomizableButtonStyle(backgroundColor: bgColor, foregroundColor: fgColor)
    }
    
}
