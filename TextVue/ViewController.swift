//
//  ViewController.swift
//  TextVue
//
//  Created by Rubaia Ambia on 3/14/21.
//

import Vision
import UIKit
import ImageCaptureCore
import AVKit
import CoreVideo

class ViewController: UIViewController {
    
    
    //Activated when the view’s content is first painted to the screen

    override func viewDidAppear(_ animated: Bool) { er
        cameraView()
    }
    
    //Create a view that will host the camera's live feed
    private func cameraView(){
        //Make a parent view the size of the current view on the screen
        let parentView = UIView()
        parentView.frame = view.frame
        parentView.backgroundColor = UIColor.lightGray
        parentView.isUserInteractionEnabled = true
        parentView.layer.cornerRadius = 20
        parentView.alpha = 1
        parentView.clipsToBounds = true
        parentView.frame.origin = CGPoint(x: 0, y: view.frame.maxY)
        
        //Animate the view to pop into place from the bottom of the screen with a little bounce in the animation
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: .curveEaseIn){[self] in
            parentView.frame.origin = CGPoint(x: 0, y: view.frame.minY)
        }
        
        //Add this view above all of the other views in the entire view hierarchy including navigation and tab bars
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(parentView)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        createNavButtons()
    }
    
    //Create the navigation buttons
    func createNavButtons(){
        //Instantiate button and set size parameters
        let cameraButton = UIButton()
        cameraButton.frame.size.height = 40
        cameraButton.frame.size.width = cameraButton.frame.height
        
        //Background/ border color and border properties
        cameraButton.backgroundColor = UIColor.white
        cameraButton.layer.borderColor = UIColor.black.cgColor
        cameraButton.layer.borderWidth = 1
        cameraButton.layer.cornerRadius = cameraButton.frame.height/2
        
        //Setting image and image color for button
        var image = UIImage(systemName: "camera")
        cameraButton.setImage( image, for: .normal)
        cameraButton.tintColor = UIColor.darkGray
        
        //Setting position of button
        cameraButton.frame.origin = CGPoint(x: view.frame.midX - cameraButton.frame.width/2, y: view.frame.midY - cameraButton.frame.height/2)
        
        //Add the button to the view in question
        view.addSubview(cameraButton)
        
        //Instantiate button and set size parameters
        let importButton = UIButton()
        importButton.frame.size.height = 40
        importButton.frame.size.width = importButton.frame.height
        
        //Background/ border color and border properties
        importButton.backgroundColor = UIColor.white
        importButton.layer.borderColor = UIColor.black.cgColor
        importButton.layer.borderWidth = 1
        importButton.layer.cornerRadius = importButton.frame.height/2
        
        //Setting image and image color for button
        image = UIImage(systemName: "camera")
        importButton.setImage( image, for: .normal)
        importButton.tintColor = UIColor.darkGray
        
        //Setting position of button
        importButton.frame.origin = CGPoint(x: view.frame.midX - importButton.frame.width/2 - (importButton.frame.width + 10), y: view.frame.midY - importButton.frame.height/2)
        
        //Add the button to the view in question
        view.addSubview(importButton)
        
        //Instantiate button and set size parameters
        let pastScansButton = UIButton()
        pastScansButton.frame.size.height = 40
        pastScansButton.frame.size.width = cameraButton.frame.height
        
        //Background/ border color and border properties
        pastScansButton.backgroundColor = UIColor.white
        pastScansButton.layer.borderColor = UIColor.black.cgColor
        pastScansButton.layer.borderWidth = 1
        pastScansButton.layer.cornerRadius = cameraButton.frame.height/2
        
        //Setting image and image color for button
        image = UIImage(systemName: "camera")
        pastScansButton.setImage( image, for: .normal)
        pastScansButton.tintColor = UIColor.darkGray
        
        //Setting position of button
        pastScansButton.frame.origin = CGPoint(x: view.frame.midX - pastScansButton.frame.width/2  + (pastScansButton.frame.width + 10), y: view.frame.midY - pastScansButton.frame.height/2)
        
        //Add the button to the view in question
        view.addSubview(pastScansButton)
    }
}

