//
//  Global.swift
//  TextVue
//
//  Created by Rubaia Ambia on 8/24/21.
//

import Foundation
import SwiftUI
import ARKit

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

extension float4x4 {
    var translation: simd_float3 {
        let translation = self.columns.3
        return simd_float3(translation.x, translation.y, translation.z)
    }
}

extension UILabel {
    var numberOfVisibleLines: Int {
            let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
            let textHeight = sizeThatFits(maxSize).height
            let lineHeight = font.lineHeight
            return Int(ceil(textHeight / lineHeight))
        }
}

extension UIView{
    //Dashed Border Methods
    func addDashedBorder(strokeColor: UIColor, fillColor: UIColor, lineWidth: CGFloat, lineDashPattern: [NSNumber], cornerRadius: CGFloat){        
        let shapeLayer:CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = fillColor.cgColor
        shapeLayer.strokeColor = strokeColor.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = lineDashPattern
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: cornerRadius).cgPath
        shapeLayer.name = "DashedBorder"
        
        self.layer.addSublayer(shapeLayer)
    }
    
    func updateDashedBorder(cornerRadius: CGFloat, strokeColor: UIColor){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.name != nil else{
            return
        }
        
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        dashedBorderLayer.bounds = shapeRect
        dashedBorderLayer.strokeColor = strokeColor.cgColor
        dashedBorderLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        dashedBorderLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: cornerRadius).cgPath
    }
    
    /** This gives the dashed border the marching ants effect where the lines are moving continuously*/
    func animateDashedBorder(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        let lineDashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        lineDashAnimation.fromValue = 0
        lineDashAnimation.toValue = dashedBorderLayer.lineDashPattern?.reduce(0) { $0 + $1.intValue }
        lineDashAnimation.duration = 1
        lineDashAnimation.repeatCount = Float.greatestFiniteMagnitude
        
        dashedBorderLayer.add(lineDashAnimation, forKey: "AntsMarchingAnimation")
    }
    
    func pauseDashedBorderAnimation(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.animation(forKey: "AntsMarchingAnimation") != nil else{
            return
        }
        dashedBorderLayer.pauseAnimation()
    }
    
    func startDashedBorderAnimation(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        guard dashedBorderLayer.animation(forKey: "AntsMarchingAnimation") != nil else{
            return
        }
        
        dashedBorderLayer.resumeAnimation()
    }
    
    /** Converts the dashed border into a single lined border and removes all prior animations assigned to the dashed border shape layer*/
    func convertDashedBorderToStraightBorder(){
        guard self.layer.sublayers != nil else{
            return
        }
        
        var dashedBorderLayer = CAShapeLayer()
        for layer in self.layer.sublayers!{
            if(layer.name == "DashedBorder"){
                dashedBorderLayer = layer as! CAShapeLayer
            }
        }
        
        pauseDashedBorderAnimation()
        dashedBorderLayer.removeAllAnimations()
        
        dashedBorderLayer.lineDashPattern = [1,0]
    }
    //Dashed Border Methods
}

extension CALayer
    {
        func pauseAnimation() {
            if isPaused() == false {
                let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
                speed = 0.0
                timeOffset = pausedTime
            }
        }

        func resumeAnimation() {
            if isPaused() {
                let pausedTime = timeOffset
                speed = 1.0
                timeOffset = 0.0
                beginTime = 0.0
                let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
                beginTime = timeSincePause
            }
        }

        func isPaused() -> Bool {
            return speed == 0
        }
    }
