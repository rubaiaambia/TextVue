//
//  pastHistoryViewController.swift
//  TextVue
//
//  Created by Justin Cook on 8/27/21.
//

import Foundation
import SwiftUI

public class PastHistoryViewController: UIViewController{
    /**button that enables the user to dismiss the current view*/
    var dismissViewButton = UIButton()
    /**The view controller presenting this view*/
    var presentingVC: HomeViewController!
    /** The UIView that hosts the content within this view*/
    lazy var contentView: UIView = getContentView()
    
    //VC Dismissal Handlers
    /**Handler for the dismissal button which animates the view controller being disposed of*/
    @objc func dismissVCButtonPressed(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        presentingVC.presentationComplete()
        self.dismiss(animated: true)
    }
    
    /**When the view disappears this method handles the clean up*/
    public override func viewDidDisappear(_ animated: Bool){
        super.viewDidDisappear(animated)
        if isBeingDismissed{
            presentingVC.presentationComplete()
        }
    }
    //VC Dismissal Handlers
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    /** Set up all the styling properties for this view's UI*/
    func setUI(){
        view.clipsToBounds = true
        view.addSubview(contentView)
        
        view.backgroundColor = UIColor.clear
        contentView.backgroundColor = mainBackgroundColor
        
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
            dismissViewButton.frame.origin = CGPoint(x: contentView.frame.width - 50, y: 10)
        }
        UIView.animate(withDuration: 0.25, delay: 0.5){ [self] in
            dismissViewButton.alpha = 1
        }
        
        contentView.addSubview(dismissViewButton)
    }
}
