//
//  ImageProcessingViewController.swift
//  TextVue
//
//  Created by Justin Cook on 8/29/21.
//

import Foundation
import SwiftUI

public class ImageProcessingViewController: UIViewController{
    /**button that enables the user to dismiss the current view*/
    var dismissViewButton = UIButton()
    /**The view controller presenting this view*/
    var presentingVC: HomeViewController!
    /** The UIView that hosts the content within this view*/
    lazy var contentView: UIView = getContentView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    /** Set up all the styling properties for this view's UI*/
    func setUI(){
        view.clipsToBounds = true
        view.addSubview(contentView)
        
        view.backgroundColor = UIColor.clear
        contentView.backgroundColor = mainBackgroundColor.withAlphaComponent(0.95)
        
        createDismissButton()
    }
    
    /** Creat the UIView that hosts the content within this view*/
    func getContentView()->UIView{
        let CV = UIView(frame: CGRect(x: 0, y: 0, width: presentingVC.view.frame.width, height: presentingVC.view.frame.height))
        
        return CV
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
            dismissViewButton.frame.origin = CGPoint(x: view.frame.width - 50, y: 50)
        }
        UIView.animate(withDuration: 0.25, delay: 0.5){ [self] in
            dismissViewButton.alpha = 1
        }
        
        contentView.addSubview(dismissViewButton)
    }
    
    /**Handler for the dismissal button which animates the view controller being disposed of*/
    @objc func dismissVCButtonPressed(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        
        navigationController?.popViewController(animated: false)
        presentingVC.view.addSubview(view)
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
            view.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
            view.frame.origin = CGPoint(x: UIScreen.main.bounds.width/2 - view.frame.width/2, y: UIScreen.main.bounds.height/2 - view.frame.height/2)
        }
        /** Dispose of this UIView from memory*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
            view.removeFromSuperview()
        }
    }
}
