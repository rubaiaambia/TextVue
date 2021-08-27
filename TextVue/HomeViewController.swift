//
//  HomeViewController.swift
//  TextVue
//
//  Created by Rubaia Ambia on 3/14/21.
//
import AVFoundation
import Vision
import UIKit
import ImageCaptureCore
import AVKit
import CoreVideo

class HomeViewController: UIViewController, AVCapturePhotoCaptureDelegate{
    @IBOutlet weak var translationSegmentedControl: UISegmentedControl!
    /**Import from Photo Library Button*/
    var importButton = UIButton()
    /**Text to  speech Button*/
    var textToSpeechButton = UIButton()
    /**Past History Button*/
    var pastHistoryButton = UIButton()
    /**Transcribe Speech Bubble Button*/
    var transcribeSpeechBubbleButton = UIButton()
    /**Flash Light Button*/
    var flashLightButton = UIButton()
    /**Capture picture Button*/
    var capturePictureButton = UIButton()
    /**Profile Button*/
    var myProfileButton = UIButton()
    /**Settings Menu Button*/
    var settingsButton = UIButton()
    
    var bottomNavButtons = [UIButton]()
    var topNavButtons = [UIButton]()
    
    /** Radial Borders that are animated around the capture button*/
    var radialBorder1 = UIView()
    var radialBorder2 = UIView()
    var radialBorder3 = UIView()
    
    var bottomButtonSize: CGFloat = 0
    var topButtonSize: CGFloat = 0
    
    /**Capture Session variables*/
    var captureSession: AVCaptureSession = AVCaptureSession()
    var stillImageOutput: AVCapturePhotoOutput =  AVCapturePhotoOutput()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    /**Blurred UIView that can overlayed ontop of another view as a subview*/
    lazy var blurredView = getBlurredView()
    
    /** Detect if the user interfaxe style has changed when the trait collection is altered either by device orientation changes or appearance changes to name a few*/
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let hasUserInterfaceStyleChanged = previousTraitCollection!.hasDifferentColorAppearance(comparedTo: traitCollection)
        if(hasUserInterfaceStyleChanged == true){
            let _ = traitCollection.userInterfaceStyle // Either .unspecified, .light, or .dark // Update your user interface based on the appearance }
            loadDarkModePreference()
        }
    }
    
    /**Create a blurred UIView and return it back to a lazy variable to be used when it's needed*/
    func getBlurredView()->UIVisualEffectView{
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        effectView.frame = view.frame
        return effectView
    }
    
    /**Activated when the view’s content is first painted to the screen*/
    override func viewWillAppear(_ animated: Bool){
        loadDarkModePreference()
        presetCameraPreview()
        configureThisView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    @objc func appMovedToBackground(){
        view.addSubview(blurredView)
    }
    
    @objc func appMovedToForeground(){
        blurredView.removeFromSuperview()
        removeCaptureButtonAnimations()
        animateCaptureButton()
    }
    
    /** Set up notifications from app delegate to know when the app goes to or from the background state*/
    func setNotificationCenter(){
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        setNotificationCenter()
        setCameraView()
        setNavButtons()
        setTopNavButtons()
    }
    
    //Logic for viewing capturing and processing images
    /** Access the camera and set up the specifications for the hardware API*/
    func setCameraView(){
        captureSession.sessionPreset = .high
        guard let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        else {
            print("Unable to access back camera!")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    /** Set the frame of the camera preview to that of the view's frame to prevent this resizing from */
    func presetCameraPreview(){
        videoPreviewLayer.frame = view.frame
    }
    
    /** Create a video preview that corresponds to the dimensions of the user's device*/
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        
        view.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async{[self] in
            captureSession.startRunning()
            constrainPreviewLayer()
        }
    }
    
    /** Constrain the video preview's layer to the dimensions of the device*/
    func constrainPreviewLayer(){
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            videoPreviewLayer.frame = view.bounds
            videoPreviewLayer.frame.size.height = videoPreviewLayer.frame.size.height - bottomButtonSize
        }
    }
    
    /** Button activated logic that triggers a capture event from the output protocol*/
    @objc func takePhoto(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        stillImageOutput.capturePhoto(with: settings, delegate: self)
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation()
            else { return }
        
        let image = UIImage(data: imageData)
        let imageView = UIImageView()
        imageView.image = image
        imageView.frame = view.frame
        imageView.contentMode = .scaleAspectFill
        
        view.addSubview(imageView)
    }
    //Logic for viewing capturing and processing images
    
    /** Basic styling for the current view presented by this view controller class*/
    func configureThisView(){
        //self.view.backgroundColor = backgroundColor
    }
    
    /** Create Top navigation buttons*/
    func setTopNavButtons(){
        topButtonSize = view.frame.width/4 - view.frame.width * 0.12
        
        translationSegmentedControl.selectedSegmentTintColor = UIColor.white
        translationSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        translationSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: appThemeColor], for: .selected)
        translationSegmentedControl.frame.origin = CGPoint(x: view.frame.width/2 - translationSegmentedControl.frame.width/2, y: view.safeAreaInsets.top + translationSegmentedControl.frame.height)
        translationSegmentedControl.isExclusiveTouch = true
        
        view.bringSubviewToFront(translationSegmentedControl)
        
        myProfileButton = UIButton(frame: CGRect(x: view.frame.minX + topButtonSize/4, y: translationSegmentedControl.frame.origin.y + topButtonSize/4, width: topButtonSize, height: topButtonSize))
        myProfileButton.setImage(UIImage(systemName: "person.crop.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        myProfileButton.tintColor = UIColor.white
        myProfileButton.imageView?.contentMode = .scaleAspectFit
        myProfileButton.contentHorizontalAlignment = .center
        myProfileButton.layer.cornerRadius = myProfileButton.frame.height/2
        myProfileButton.layer.shadowColor = UIColor.darkGray.cgColor
        myProfileButton.layer.shadowRadius = myProfileButton.frame.height/2
        myProfileButton.layer.shadowOpacity = 0.15
        myProfileButton.layer.shadowPath = UIBezierPath(rect: myProfileButton.bounds).cgPath
        myProfileButton.imageEdgeInsets = UIEdgeInsets(top: myProfileButton.frame.height * 0.25, left: myProfileButton.frame.height * 0.25, bottom: myProfileButton.frame.height * 0.25, right: myProfileButton.frame.height * 0.25)
        myProfileButton.backgroundColor = appThemeColor
        myProfileButton.isExclusiveTouch = true
        
        settingsButton = UIButton(frame: CGRect(x: view.frame.maxX - (topButtonSize + topButtonSize/4), y: translationSegmentedControl.frame.origin.y + topButtonSize/4, width: topButtonSize, height: topButtonSize))
        settingsButton.setImage(UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        settingsButton.tintColor = UIColor.white
        settingsButton.imageView?.contentMode = .scaleAspectFit
        settingsButton.contentHorizontalAlignment = .center
        settingsButton.layer.cornerRadius = settingsButton.frame.height/2
        settingsButton.layer.shadowColor = UIColor.darkGray.cgColor
        settingsButton.layer.shadowRadius = settingsButton.frame.height/2
        settingsButton.layer.shadowOpacity = 0.15
        settingsButton.layer.shadowPath = UIBezierPath(rect: settingsButton.bounds).cgPath
        settingsButton.imageEdgeInsets = UIEdgeInsets(top: settingsButton.frame.height * 0.25, left: settingsButton.frame.height * 0.25, bottom: settingsButton.frame.height * 0.25, right: settingsButton.frame.height * 0.25)
        settingsButton.backgroundColor = appThemeColor
        settingsButton.isExclusiveTouch = true
        
        topNavButtons.append(myProfileButton)
        topNavButtons.append(settingsButton)
        
        view.addSubview(myProfileButton)
        view.addSubview(settingsButton)
    }
    
    /**Create navigation buttons*/
    func setNavButtons(){
        bottomButtonSize = view.frame.width/4 - view.frame.width * 0.08
        
        importButton = UIButton(frame: CGRect(x: view.frame.midX - bottomButtonSize, y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
        importButton.setImage(UIImage(systemName: "icloud.and.arrow.down.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        importButton.tintColor = UIColor.white
        importButton.imageView?.contentMode = .scaleAspectFit
        importButton.contentHorizontalAlignment = .center
        importButton.layer.cornerRadius = importButton.frame.height/2
        importButton.layer.shadowColor = UIColor.darkGray.cgColor
        importButton.layer.shadowRadius = 1
        importButton.layer.shadowOpacity = 1
        importButton.clipsToBounds = true
        importButton.layer.masksToBounds = false
        importButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        importButton.layer.shadowPath = UIBezierPath(roundedRect: importButton.bounds, cornerRadius: importButton.layer.cornerRadius).cgPath
        importButton.imageEdgeInsets = UIEdgeInsets(top: importButton.frame.height * 0.25, left: importButton.frame.height * 0.25, bottom: importButton.frame.height * 0.25, right: importButton.frame.height * 0.25)
        importButton.backgroundColor = appThemeColor
        importButton.addTarget(self, action: #selector(bottomNavButtonPressed), for: .touchDown)
        importButton.tag = 0
        importButton.isExclusiveTouch = true/**Prevent other buttons from being pressed while this button is being pressed*/
        
        textToSpeechButton = UIButton(frame: CGRect(x: view.frame.midX + 10, y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
        textToSpeechButton.setImage(UIImage(systemName: "waveform", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        textToSpeechButton.tintColor = UIColor.white
        textToSpeechButton.imageView?.contentMode = .scaleAspectFit
        textToSpeechButton.contentHorizontalAlignment = .center
        textToSpeechButton.layer.cornerRadius = textToSpeechButton.frame.height/2
        textToSpeechButton.layer.shadowColor = UIColor.darkGray.cgColor
        textToSpeechButton.layer.shadowRadius = 1
        textToSpeechButton.layer.shadowOpacity = 1
        textToSpeechButton.clipsToBounds = true
        textToSpeechButton.layer.masksToBounds = false
        textToSpeechButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        textToSpeechButton.layer.shadowPath = UIBezierPath(roundedRect: textToSpeechButton.bounds, cornerRadius: textToSpeechButton.layer.cornerRadius).cgPath
        textToSpeechButton.imageEdgeInsets = UIEdgeInsets(top: textToSpeechButton.frame.height * 0.25, left: textToSpeechButton.frame.height * 0.25, bottom: textToSpeechButton.frame.height * 0.25, right: textToSpeechButton.frame.height * 0.25)
        textToSpeechButton.backgroundColor = appThemeColor
        textToSpeechButton.addTarget(self, action: #selector(bottomNavButtonPressed), for: .touchDown)
        textToSpeechButton.tag = 1
        textToSpeechButton.isExclusiveTouch = true
        
        pastHistoryButton = UIButton(frame: CGRect(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
        pastHistoryButton.setImage(UIImage(systemName: "externaldrive.fill.badge.icloud", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        pastHistoryButton.tintColor = UIColor.white
        pastHistoryButton.imageView?.contentMode = .scaleAspectFit
        pastHistoryButton.contentHorizontalAlignment = .center
        pastHistoryButton.layer.cornerRadius = pastHistoryButton.frame.height/2
        pastHistoryButton.layer.shadowColor = UIColor.darkGray.cgColor
        pastHistoryButton.layer.shadowRadius = 1
        pastHistoryButton.layer.shadowOpacity = 1
        pastHistoryButton.clipsToBounds = true
        pastHistoryButton.layer.masksToBounds = false
        pastHistoryButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        pastHistoryButton.layer.shadowPath = UIBezierPath(roundedRect: pastHistoryButton.bounds, cornerRadius: pastHistoryButton.layer.cornerRadius).cgPath
        pastHistoryButton.imageEdgeInsets = UIEdgeInsets(top: pastHistoryButton.frame.height * 0.25, left: pastHistoryButton.frame.height * 0.25, bottom: pastHistoryButton.frame.height * 0.25, right: pastHistoryButton.frame.height * 0.25)
        pastHistoryButton.backgroundColor = appThemeColor
        pastHistoryButton.addTarget(self, action: #selector(bottomNavButtonPressed), for: .touchDown)
        pastHistoryButton.tag = 2
        pastHistoryButton.isExclusiveTouch = true
        
        transcribeSpeechBubbleButton = UIButton(frame: CGRect(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
        transcribeSpeechBubbleButton.setImage(UIImage(systemName: "text.bubble.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        transcribeSpeechBubbleButton.tintColor = UIColor.white
        transcribeSpeechBubbleButton.imageView?.contentMode = .scaleAspectFit
        transcribeSpeechBubbleButton.contentHorizontalAlignment = .center
        transcribeSpeechBubbleButton.layer.cornerRadius = transcribeSpeechBubbleButton.frame.height/2
        transcribeSpeechBubbleButton.layer.shadowColor = UIColor.darkGray.cgColor
        transcribeSpeechBubbleButton.layer.shadowRadius = 1
        transcribeSpeechBubbleButton.layer.shadowOpacity = 1
        transcribeSpeechBubbleButton.clipsToBounds = true
        transcribeSpeechBubbleButton.layer.masksToBounds = false
        transcribeSpeechBubbleButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        transcribeSpeechBubbleButton.layer.shadowPath = UIBezierPath(roundedRect: transcribeSpeechBubbleButton.bounds, cornerRadius: transcribeSpeechBubbleButton.layer.cornerRadius).cgPath
        transcribeSpeechBubbleButton.imageEdgeInsets = UIEdgeInsets(top: transcribeSpeechBubbleButton.frame.height * 0.25, left: transcribeSpeechBubbleButton.frame.height * 0.25, bottom: transcribeSpeechBubbleButton.frame.height * 0.25, right: transcribeSpeechBubbleButton.frame.height * 0.25)
        transcribeSpeechBubbleButton.backgroundColor = appThemeColor
        transcribeSpeechBubbleButton.addTarget(self, action: #selector(bottomNavButtonPressed), for: .touchDown)
        transcribeSpeechBubbleButton.tag = 3
        transcribeSpeechBubbleButton.isExclusiveTouch = true
        
        flashLightButton = UIButton(frame: CGRect(x: view.frame.midX - bottomButtonSize/2, y: importButton.frame.minY - (bottomButtonSize * 1), width: bottomButtonSize, height: bottomButtonSize))
        flashLightButton.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        flashLightButton.tintColor = UIColor.white
        flashLightButton.imageView?.contentMode = .scaleAspectFit
        flashLightButton.contentHorizontalAlignment = .center
        flashLightButton.imageEdgeInsets = UIEdgeInsets(top: flashLightButton.frame.height * 0.2, left: flashLightButton.frame.height * 0.2, bottom: flashLightButton.frame.height * 0.2, right: flashLightButton.frame.height * 0.2)
        flashLightButton.backgroundColor = UIColor.clear
        flashLightButton.isExclusiveTouch = true
        
        capturePictureButton = UIButton(frame: CGRect(x: view.frame.midX - bottomButtonSize/2, y: flashLightButton.frame.minY - (bottomButtonSize), width: (bottomButtonSize), height: (bottomButtonSize)))
        capturePictureButton.setImage(UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        capturePictureButton.tintColor = UIColor.white
        capturePictureButton.imageView?.contentMode = .scaleAspectFit
        capturePictureButton.contentHorizontalAlignment = .center
        capturePictureButton.backgroundColor = UIColor.clear
        capturePictureButton.addTarget(self, action: #selector(takePhoto), for: .touchDown)
        capturePictureButton.isExclusiveTouch = true
        
        radialBorder1.frame = capturePictureButton.frame
        radialBorder2.frame = capturePictureButton.frame
        radialBorder3.frame = capturePictureButton.frame
        
        radialBorder1.layer.borderWidth = 1
        radialBorder1.layer.cornerRadius = radialBorder1.frame.height/2
        radialBorder1.layer.borderColor = appThemeColor.cgColor
        
        radialBorder2.layer.borderWidth = 1
        radialBorder2.layer.cornerRadius = radialBorder2.frame.height/2
        radialBorder2.layer.borderColor = appThemeColor.cgColor
        
        radialBorder3.layer.borderWidth = 1
        radialBorder3.layer.cornerRadius = radialBorder3.frame.height/2
        radialBorder3.layer.borderColor = appThemeColor.cgColor
        
        bottomNavButtons.append(pastHistoryButton)
        bottomNavButtons.append(importButton)
        bottomNavButtons.append(textToSpeechButton)
        bottomNavButtons.append(transcribeSpeechBubbleButton)
        
        /** Give the UI time to update before animating*/
        DispatchQueue.main.async{[self] in
            hideNavButtons(animated: false)
            showNavButtons(animated: true)
            
            hideCaptureButtons(animated: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){ [self] in
            showCaptureButtons(animated: true)
            animateCaptureButton()
        }
        
        view.addSubview(importButton)
        view.addSubview(textToSpeechButton)
        view.addSubview(pastHistoryButton)
        view.addSubview(transcribeSpeechBubbleButton)
        view.addSubview(flashLightButton)
        
        view.addSubview(radialBorder1)
        view.addSubview(radialBorder2)
        view.addSubview(radialBorder3)
        view.addSubview(capturePictureButton)
    }
    
    /** Action handler for  touch down events on the bottom navigation buttons*/
    @objc func bottomNavButtonPressed(sender: UIButton){
        /** Give the user a nice touch based reward for tapping the button*/
        hapticFeedBack(FeedbackStyle: .rigid)
        
        /** Prevent the user from triggering the button in rapid succession*/
        sender.isEnabled = false
        
        /** Make the view slightly transparent and scale it down followed by immediately undoing said transforms and alpha changes*/
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            sender.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            sender.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        UIView.animate(withDuration: 0.25){
            sender.alpha = 0.9
        }
        UIView.animate(withDuration: 0.25, delay: 0.25){
            sender.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
        sender.isEnabled = true
        }
        
        switch sender.tag{
        /** Import Button*/
        case 0:
            break
        /** Text To Speech Button*/
        case 1:
            break
        /** Past History Button triggers a custom segue*/
        case 2:
            //self.navigationController?.pushViewController(PastHistoryViewController(), animated: true)
            let pastHistoryVC = PastHistoryViewController()
            
            /** Make the view controller's view the same shape as the button*/
            pastHistoryVC.view.frame = sender.frame
            pastHistoryVC.view.layer.cornerRadius = sender.layer.cornerRadius
            
            /** Add the view controller's view to the current view controller's view as a subview*/
            view.addSubview(pastHistoryVC.view)
            
            /** Animate the circular view moving to the center of the screen and expanding into a view that encompasses the entire screen and then push this view controller's view onto the navigation controller's stack to release the memory held up by the current view controller*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                pastHistoryVC.view.frame.origin = CGPoint(x: view.frame.width/2 - pastHistoryVC.view.frame.width/2, y: view.frame.height/2 - pastHistoryVC.view.frame.height/2)
            }
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                pastHistoryVC.view.frame = view.frame
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
            navigationController?.pushViewController(pastHistoryVC, animated: false)
            }
            
        /** Transcribe Speech Bubble Button*/
        case 3:
            break
        default:
            return
        }
    }
    
    /** Shows capture buttons and associated views statically or in an animated manner*/
    func showCaptureButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 1){[self] in
                flashLightButton.alpha = 1
            }
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                radialBorder1.alpha =  1
                radialBorder2.alpha = 1
                radialBorder3.alpha = 1
            }
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){[self] in
                capturePictureButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        case false:
            flashLightButton.alpha = 1
            
            capturePictureButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            
            radialBorder1.alpha =  1
            radialBorder2.alpha = 1
            radialBorder3.alpha = 1
        }
    }
    
    /** Hides capture button and associated views statically or in an animated manner*/
    func hideCaptureButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 1){[self] in
                flashLightButton.alpha = 0
            }
            UIView.animate(withDuration: 0.25, delay: 0){[self] in
                radialBorder1.alpha =  0
                radialBorder2.alpha = 0
                radialBorder3.alpha = 0
            }
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){[self] in
                capturePictureButton.transform = CGAffineTransform(scaleX: 0, y: 0)
            }
        case false:
            flashLightButton.alpha = 0
            
            capturePictureButton.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            radialBorder1.alpha =  0
            radialBorder2.alpha = 0
            radialBorder3.alpha = 0
        }
    }
    
    /** Hide navigation buttons in a static or animated manner*/
    func hideNavButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY + bottomButtonSize * 5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - bottomButtonSize, y: view.frame.maxY + bottomButtonSize * 5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 10, y: view.frame.maxY + bottomButtonSize * 5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY + bottomButtonSize * 5)
            }
        case false:
            bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY + bottomButtonSize * 5)
            
            bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - bottomButtonSize, y: view.frame.maxY + bottomButtonSize * 5)
            
            bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 10, y: view.frame.maxY + bottomButtonSize * 5)
            
            bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY + bottomButtonSize * 5)
        }
    }
    
    /** Display navigation buttons in a static or animated manner*/
    func showNavButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - bottomButtonSize, y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 10, y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY - bottomButtonSize * 1.5)
            }
        case false:
            bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY - bottomButtonSize * 1.5)
            
            bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - bottomButtonSize, y: view.frame.maxY - bottomButtonSize * 1.5)
            
            bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 10, y: view.frame.maxY - bottomButtonSize * 1.5)
            
            bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY - bottomButtonSize * 1.5)
        }
    }
    
    /** Removes all the animations given to the capture button*/
    func removeCaptureButtonAnimations(){
        radialBorder3.layer.removeAllAnimations()
        radialBorder2.layer.removeAllAnimations()
        radialBorder1.layer.removeAllAnimations()
        capturePictureButton.layer.removeAllAnimations()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: [.curveEaseIn, .repeat, .autoreverse, .allowUserInteraction]){[self] in
            radialBorder3.transform = CGAffineTransform(scaleX: 1, y: 1)
            radialBorder2.transform = CGAffineTransform(scaleX: 1, y: 1)
            radialBorder1.transform = CGAffineTransform(scaleX: 1, y: 1)
            capturePictureButton.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
    }

    /** Animate the circular views around the caputre button and the capture button itself scaling up and down*/
    func animateCaptureButton(){
        UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: [.curveEaseIn, .repeat, .autoreverse,  .allowUserInteraction]){[self] in
            radialBorder3.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            capturePictureButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        UIView.animate(withDuration: 1.5, delay: 1, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: [.curveEaseIn, .repeat, .autoreverse]){[self] in
            radialBorder2.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        UIView.animate(withDuration: 1.5, delay: 2, usingSpringWithDamping: 0.7, initialSpringVelocity: 10, options: [.curveEaseIn, .repeat, .autoreverse]){[self] in
            radialBorder1.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
    }
    
}

