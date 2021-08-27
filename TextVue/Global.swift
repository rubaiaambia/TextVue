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
/**Darkmode Preference*/
var isDarkModeEnabled = false
var useSystemUIAppearance = true
var backgroundColor = UIColor.white
var fontColor = UIColor.black
var secondaryBackgroundColor = UIColor.lightGray

/** Remove the current object stored for the given key, refresh the user defaults database to await any pending updates, and then set a new object for the given key*/
func saveDarkModePreference(){
    UserDefaults.standard.removeObject(forKey: "Darkmode")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(isDarkModeEnabled, forKey: "Darkmode")
    
    UserDefaults.standard.removeObject(forKey: "UseSystemUIAppearance")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(useSystemUIAppearance, forKey: "UseSystemUIAppearance")
}

/** Load the user's dark mode preference based on */
func loadDarkModePreference(){
    /** Used to detect whether an object is present for the given key in user defaults*/
    var isObjectPresent = false
    
    /** Load up the user's dark mode preference from user defaults*/
    if let bool = UserDefaults.standard.object(forKey: "Darkmode") as? Bool{
        isDarkModeEnabled = bool
        isObjectPresent = true
    }
    
    /** Load up the user's usage of UI Appearance for darkmode preference from user defaults*/
    if let bool = UserDefaults.standard.object(forKey: "UseSystemUIAppearance") as? Bool{
        useSystemUIAppearance = bool
    }
    
    /** If no darkmode preference exists then simply set the preference depending on the user's device appearance or if the user has specified that they wish to use their system preferences then use this, either way this is the default*/
    if(isObjectPresent == false || useSystemUIAppearance == true){
    switch UITraitCollection.current.userInterfaceStyle{
    case .dark:
        isDarkModeEnabled = true
    case .light:
        isDarkModeEnabled = false
    case .unspecified:
        isDarkModeEnabled = false
    @unknown default:
        isDarkModeEnabled = false
    }
    }
    setDarkModeTraits()
}

/** Set the background color and font color and secondary background color attributes depending on what the current darkmode preference is*/
func setDarkModeTraits(){
    switch isDarkModeEnabled{
    case true:
        backgroundColor = UIColor.black
        fontColor = UIColor.white
        secondaryBackgroundColor = UIColor.darkGray
    case false:
        backgroundColor = UIColor.white
        fontColor = UIColor.black
        secondaryBackgroundColor = UIColor.lightGray
    }
}

/** Trigger various types of haptic feedback for the user to gawk over when they tap a button*/
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
