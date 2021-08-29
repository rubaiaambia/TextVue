//
//  MyProfileViewController.swift
//  TextVue
//
//  Created by Justin Cook on 8/29/21.
//

import Foundation
import SwiftUI

/** View that displays the local-only profile of the user*/
public class MyProfileView: UIView{
    /**button that enables the user to dismiss the current view*/
    var dismissViewButton = UIButton()
    /**Specifies the original size the view of this view controller should go back to when a dismissal animation is being played which is the reverse of the custom appearance segue*/
    var originalSize: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    /**Specifies the original location the view of this view controller should go back to when a dismissal animation is being played which is the reverse of the custom appearance segue*/
    var originalLocation: CGPoint = CGPoint(x: 0, y: 0)
    /**The view controller presenting this view*/
    var presentingVC: HomeViewController!
    /** The UIView that hosts the content within this view*/
    lazy var contentView: UIView = getContentView()
    
    /** Initialization method that specifies required properties and launches any necessary methods for the function of this UIView*/
    init(presentingVC: HomeViewController){
        self.presentingVC = presentingVC
        super.init(frame: .zero)
        setUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**Sets the original size the view of this view controller should go back to when a dismissal animation is being played which is the reverse of the custom appearance segue*/
    func setOriginalSize(frame: CGRect){
        originalSize = frame
    }
    
    /**Sets the original location the view of this view controller should go back to when a dismissal animation is being played which is the reverse of the custom appearance segue*/
    func setOriginalLocation(point: CGPoint){
        originalLocation = point
    }
    
    /** Creat the UIView that hosts the content within this view*/
    func getContentView()->UIView{
        let CV = UIView(frame: CGRect(x: 0, y: 0, width: presentingVC.view.frame.width * 0.9, height: presentingVC.view.frame.height * 0.9))
        
        return CV
    }
    
    /** Set up all the styling properties for this view's UI*/
    func setUI(){
        self.addSubview(contentView)
        
        self.backgroundColor = UIColor.clear
        contentView.backgroundColor = mainBackgroundColor.withAlphaComponent(0.95)
        
        createDismissButton()
    }
    
    /** Creates a button that enables the user to dismiss the current view controller*/
    func createDismissButton(){
        dismissViewButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        dismissViewButton.backgroundColor = appThemeColor
        dismissViewButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        dismissViewButton.layer.cornerRadius = dismissViewButton.frame.height/2
        dismissViewButton.isExclusiveTouch = true
        dismissViewButton.clipsToBounds = true
        dismissViewButton.imageEdgeInsets = UIEdgeInsets(top: dismissViewButton.frame.height * 0.25, left: dismissViewButton.frame.height * 0.25, bottom: dismissViewButton.frame.height * 0.25, right: dismissViewButton.frame.height * 0.25)
        dismissViewButton.tintColor = UIColor.white
        dismissViewButton.imageView?.contentMode = .scaleAspectFit
        dismissViewButton.contentHorizontalAlignment = .center
        /** Shadow Properties*/
        dismissViewButton.layer.shadowColor = UIColor.darkGray.cgColor
        dismissViewButton.layer.shadowRadius = 1
        dismissViewButton.layer.shadowOpacity = 1
        dismissViewButton.layer.masksToBounds = false
        dismissViewButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        dismissViewButton.layer.shadowPath = UIBezierPath(roundedRect: dismissViewButton.bounds,cornerRadius: dismissViewButton.layer.cornerRadius).cgPath
        dismissViewButton.addTarget(self, action: #selector(dismissVCButtonPressed), for: .touchDown)
        dismissViewButton.alpha = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){ [self] in
            dismissViewButton.frame.origin = CGPoint(x: self.frame.width - 50, y: 10)
        }
        UIView.animate(withDuration: 0.25, delay: 0.5){ [self] in
            dismissViewButton.alpha = 1
        }
        
        contentView.addSubview(dismissViewButton)
    }
    
    /**Handler for the dismissal button which animates the view controller being disposed of*/
    @objc func dismissVCButtonPressed(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
            self.frame = originalSize
            self.frame.origin = CGPoint(x: UIScreen.main.bounds.width/2 - self.frame.width/2, y: UIScreen.main.bounds.height/2 - self.frame.height/2)
        }
        UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
            self.frame.origin = originalLocation
            self.alpha = 0
        }
        /** Inform the home view controller that this view is done being presented*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
            presentingVC.presentationComplete()
        }
        /** Dispose of this UIView from memory*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
            self.removeFromSuperview()
        }
    }
    
}
