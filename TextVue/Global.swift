//
//  Global.swift
//  TextVue
//
//  Created by Rubaia Ambia on 8/24/21.
//

import Foundation
import SwiftUI

/**Lilac  Color*/
let appThemeColor = UIColor(red: 193/255, green: 162/255, blue: 197/255, alpha: 1)

func hapticFeedBack(FeedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle){
    switch FeedbackStyle{
    case .light:
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .medium:
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    case .heavy:
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    case .soft:
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    case .rigid:
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    @unknown default:
        break
    }
}
