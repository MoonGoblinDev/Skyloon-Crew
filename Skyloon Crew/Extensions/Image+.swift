//
//  Image+.swift
//  iCon
//
//  Created by Reza Juliandri on 30/05/25.
//
import SwiftUI

extension Image {
    func fromAsset(
        top: CGFloat = 29,
        leading: CGFloat = 29,
        bottom: CGFloat = 29,
        trailing: CGFloat = 29,
        allInsets: CGFloat = 0,
        width: CGFloat? = nil,
        height: CGFloat? =  nil
    ) -> some View {
        var target = self
        if allInsets > 0 {
            target = target.resizable(capInsets: .init(top: allInsets, leading: allInsets, bottom: allInsets, trailing: allInsets))
        } else {
            target = target.resizable(capInsets: .init(top: top, leading: leading, bottom: bottom, trailing: trailing))
            
        }
        return target.frame(width: width, height: height)
    }
}
