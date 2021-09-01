//
//  Global.swift
//  TextVue
//
//  Created by Rubaia Ambia on 8/24/21.
//

import Foundation
import SwiftUI

//Custom Colors
/**Lilac  Color*/
let appThemeColor = UIColor(red: 193/255, green: 162/255, blue: 197/255, alpha: 1)
/**systemGray6*/
var systemGray6: UIColor = UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1)
/**Darkmode Preference*/
var isDarkModeEnabled = false
/**Bool that controls whether darkmode is controlled by the user's system appearance preferences or not*/
var useSystemUIAppearance = true
/**Background color given to any applicable view*/
var mainBackgroundColor = UIColor.white
/**font  color given to any applicable text*/
var fontColor = UIColor.black
/**Secondary Background color given to any applicable view*/
var secondaryBackgroundColor = UIColor.lightGray
/**Bool that controls device torch*/
var flashLightOn = false
/**Bool that controls which camera to use*/
var useBackCamera = true
/**Bool that controls the segmented control at the top of the view to switch between a normal camera photo taking mode to an augmented reality scene*/
var augmentedRealityModeEnabled = false

/** Loads all user default preferences saved in memory if any*/
func loadUserPreferences(){
    loadCameraPreferences()
    loadDarkModePreference()
    loadPhotoARModePreference()
}

/** Saves all user default preferences to local storage*/
func saveUserPreferences(){
    saveCameraPreferences()
    saveDarkModePreference()
    savePhotoARModePreference()
}

/** Load the user's preferences for the photo mode or AR mode segemented control*/
func loadPhotoARModePreference(){
    /** Load up the user's preference for whether to use the back camera or front camera*/
    if let bool = UserDefaults.standard.object(forKey: "AREnabled") as? Bool{
        augmentedRealityModeEnabled = bool
    }
}

/** Save the user's preferences for the photo mode or AR mode segemented control*/
func savePhotoARModePreference(){
    UserDefaults.standard.removeObject(forKey: "AREnabled")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(augmentedRealityModeEnabled, forKey: "AREnabled")
}

/** Load the user's preferences for camera specific functionalities*/
func loadCameraPreferences(){
    /** Load up the user's preference for whether to use the back camera or front camera*/
    if let bool = UserDefaults.standard.object(forKey: "CameraDevice") as? Bool{
        useBackCamera = bool
    }
    
    /** Load up the user's preference for whether to use the flashlight or not*/
    if let bool = UserDefaults.standard.object(forKey: "FlashLightBool") as? Bool{
        flashLightOn = bool
    }
}

/** Save the user's preferences for camera specific functionalities*/
func saveCameraPreferences(){
    UserDefaults.standard.removeObject(forKey: "CameraDevice")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(useBackCamera, forKey: "CameraDevice")
    
    UserDefaults.standard.removeObject(forKey: "FlashLightBool")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(flashLightOn, forKey: "FlashLightBool")
}

/** Save the user's dark mode preference based on whether they use the system's appearance or the in app toggle*/
/** Remove the current object stored for the given key, refresh the user defaults database to await any pending updates, and then set a new object for the given key*/
func saveDarkModePreference(){
    UserDefaults.standard.removeObject(forKey: "Darkmode")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(isDarkModeEnabled, forKey: "Darkmode")
    
    UserDefaults.standard.removeObject(forKey: "UseSystemUIAppearance")
    UserDefaults.standard.synchronize()
    UserDefaults.standard.set(useSystemUIAppearance, forKey: "UseSystemUIAppearance")
}

/** Load the user's dark mode preference based on whether they use the system's appearance or the in app toggle*/
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
        mainBackgroundColor = systemGray6
        fontColor = UIColor.white
        secondaryBackgroundColor = UIColor.darkGray
    case false:
        mainBackgroundColor = UIColor.white
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
