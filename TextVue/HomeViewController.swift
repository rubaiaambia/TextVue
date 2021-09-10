//
//  HomeViewController.swift
//  TextVue
//
//  Created by Rubaia Ambia on 3/14/21.
//
/** -   Description: TextVue is an app that allows you to parse all kinds of texts from your environment. Whether your content is live, still, or imported from your camera roll, bysing advanced text recognition API and AI denoising techniques TextVue can see even when there's nothing to see, and with the power of augmented reality, discovering the world around you and grabbing text to use in other applications with the tap of a finger never seemed so easy. Welcome home to innovation, where we all should be.
 - Authors: Rubaia Ambia, Justin Cook*/

/**Necessary libraries for the API necessary to make this application possible*/
import AVFoundation
import Vision
import UIKit
import ImageCaptureCore
import AVKit
import CoreVideo
import ARKit

/**The base of operations this is where the magic happens and all other areas of the app are rerouted to*/
class HomeViewController: UIViewController, AVCapturePhotoCaptureDelegate, ARCoachingOverlayViewDelegate{
    @IBOutlet weak var photoARModeSegmentedControl: UISegmentedControl!
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
    /**A bright UIView that increases the brightness of the environment when the user wants to take a front facing photo with torch options on*/
    lazy var artificialFlashLight:UIView = artificialFlash()
    /**Switch Camera Button*/
    var switchCameraButton = UIButton()
    /**Capture picture Button*/
    var capturePictureButton = UIButton()
    /**Profile Button*/
    var myProfileButton = UIButton()
    /**Settings Menu Button*/
    var settingsButton = UIButton()
    /** An array of all navigation buttons on the bottom of the screen*/
    var bottomNavButtons = [UIButton]()
    /** An array of all navigation buttons at the top of the screen*/
    var topNavButtons = [UIButton]()
    
    /** Radial Borders that are animated around the capture button*/
    var radialBorder1 = UIView()
    var radialBorder2 = UIView()
    var radialBorder3 = UIView()
    
    /** Height and width variables for the bottom and top navigation buttons*/
    var bottomButtonSize: CGFloat = 0
    var topButtonSize: CGFloat = 0
    var selectionButtonSize: CGFloat = 0
    
    /**Capture Session variables*/
    var captureSession: AVCaptureSession!
    /**Static Photo output by the capture session*/
    var stillImageOutput: AVCapturePhotoOutput!
    /**Video preview of what the camera currently sees*/
    var videoPreviewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    /**Prevent multiple video preview layers from being painted on top of one another when switching between cameras*/
    var videoPreviewLayerActive = false
    /**The current device responsible for the input of the capture session*/
    lazy var currentCamera: AVCaptureDevice? = getCamera()
    /**The zoom level of the camera*/
    var zoomFactor: CGFloat = 1
    /**Button that displays the current zoom factor and enables fast manipulation of it versus pinching*/
    var zoomFactorButton: UIButton = UIButton()
    /** Rectangle for the content size and location of the video preview layer and AR scene for displaying what the camera currently sees*/
    lazy var contentFrame: CGRect = getContentFrame()
    
    /**Blurred UIView that can overlayed ontop of another view as a subview*/
    lazy var blurredView = getBlurredView()
    /**Specify if a view is being presented, if it is then the blurred view is already added to the main screen*/
    var isTransientViewBeingPresented = false
    
    /** Augmented Reality variables*/
    var configuration: ARWorldTrackingConfiguration!
    /** The view in which the augmented reality scene is constructed in*/
    var sceneView: ARSCNView = ARSCNView()
    var coachingOverlayView = ARCoachingOverlayView()
    var selectionBox: UIView!
    var confirmSelectionButton = UIButton()
    var cancelSelectionButton = UIButton()
    /** An array of scene nodes*/
    var nodes = [SCNNode]()
    
    
    /**Get the camera device that will be used for the capture session, defaults automatically use the best format and frame rate for the current device*/
    func getCamera()->AVCaptureDevice?{
        loadCameraPreferences()
        switch useBackCamera{
        case true:
            if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back){
                return captureDevice
            }
            else{
                return nil
            }
        case false:
            if let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front){
                return captureDevice
            }
            else{
                return nil
            }
        }
    }
    
    /** Detect if the user interfaxe style has changed when the trait collection is altered either by device orientation changes or appearance changes to name a few*/
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let hasUserInterfaceStyleChanged = previousTraitCollection!.hasDifferentColorAppearance(comparedTo: traitCollection)
        if(hasUserInterfaceStyleChanged == true){
            let _ = traitCollection.userInterfaceStyle // Either .unspecified, .light, or .dark // Update your user interface based on the appearance }
            loadDarkModePreference()
        }
        
    }
    
    /**Activated when the view’s content is first painted to the screen*/
    override func viewWillAppear(_ animated: Bool){
        if isTransientViewBeingPresented == false{
            blurredView.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool){
        saveUserPreferences()
    }
    
    @objc func appIsInBackground(){
        switch augmentedRealityModeEnabled{
        case true:
            break
        case false:
            resetZoomLevel()
        }
    }
    
    @objc func appMovedToBackground(){
        if isTransientViewBeingPresented == false{
            view.addSubview(blurredView)
        }
        
        switch augmentedRealityModeEnabled{
        case true:
            sceneView.session.pause()
        case false:
            guard captureSession != nil else {
                return
            }
            captureSession.stopRunning()
        }
    }
    
    @objc func appMovedToForeground(){
        if isTransientViewBeingPresented == false{
            blurredView.removeFromSuperview()
        }
        removeCaptureButtonAnimations()
        animateCaptureButton()
    }
    
    /** Activates when the application regains focus*/
    @objc func appDidBecomeActive(){
        if isTransientViewBeingPresented == false{
            blurredView.removeFromSuperview()
        }
        
        switch augmentedRealityModeEnabled{
        case true:
            startARSession()
        case false:
            break
        }
        
        guard captureSession != nil else {
            return
        }
        
        switch augmentedRealityModeEnabled{
        case true:
            break
        case false:
            captureSession.startRunning()
        }
    }
    
    /** Set up notifications from app delegate to know when the app goes to or from the background state*/
    func setNotificationCenter(){
        let notifCenter = NotificationCenter.default
        notifCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        notifCenter.addObserver(self, selector: #selector(appIsInBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        loadUserPreferences()
        setNotificationCenter()
        
        switch augmentedRealityModeEnabled{
        case true:
            addARScene()
        case false:
            setCameraView()
        }
        
        constrainARScene()
        setZoomFactorButton()
        addGestureRecognizers()
        setNavButtons()
        setTopNavButtons()
        setSelectionButtons()
    }
    
    /** Displays general information about the AR Scene such as frames per second and timing*/
    func displayARSceneStats(){
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    /** Configure the world tracking and start the AR Session*/
    func startARSession(){
        // Reset the session.
        configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking])
    }
    
    /** Create and add the ARCoachingOverlayView to the viewcontroller's view*/
    func setCoach(){
        coachingOverlayView.frame = view.frame
        // Make sure it rescales if the device orientation changes
        coachingOverlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Set the Augmented Reality goal
        coachingOverlayView.goal = .verticalPlane
        // Set the ARSession
        coachingOverlayView.session = sceneView.session
        // Set the delegate for any callbacks
        coachingOverlayView.delegate = self
        
        view.addSubview(coachingOverlayView)
    }
    
    /** To make sure the coaching overlay provides guidance to the user whenever ARKit determines it’s necessary, you set activatesAutomatically to true.*/
    func setActivatesAutomatically(){
        coachingOverlayView.activatesAutomatically = true
    }
    
    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        //upperControlsView.isHidden = true
    }
    
    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        //upperControlsView.isHidden = false
    }
    
    func coachingOverlayViewDidRequestSessionReset(_ coachingOverlayView: ARCoachingOverlayView) {
        startARSession()
    }
    
    //Logic for viewing capturing and processing images
    /**Create a blurred UIView and return it back to a lazy variable to be used when it's needed*/
    func getBlurredView()->UIVisualEffectView{
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        effectView.frame = view.frame
        return effectView
    }
    
    /** Access the camera and set up the specifications for the hardware API*/
    func setCameraView(){
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        guard currentCamera != nil
        else {
            print("Unable to access camera!")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: currentCamera!)
            stillImageOutput = AVCapturePhotoOutput()
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                if(videoPreviewLayerActive == false){
                    setupLivePreview()
                    videoPreviewLayerActive = true
                }
            }
        }
        catch let error  {
            print("Error Unable to initialize camera:  \(error.localizedDescription)")
        }
    }
    
    /** Create a video preview that corresponds to the dimensions of the user's device*/
    func setupLivePreview(){
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        /** Set the frame of the camera preview to that of the view's frame to prevent this resizing from */
        videoPreviewLayer.frame = view.frame
        
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        
        view.layer.addSublayer(videoPreviewLayer)
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async{[self] in
            constrainPreviewLayer()
            captureSession.startRunning()
        }
    }
    
    /** Constrain the video preview's layer to the dimensions of the device*/
    func constrainPreviewLayer(){
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            videoPreviewLayer.frame = contentFrame
        }
    }
    
    //Augmented Reality methods
    /** Add the Augmented reality scene to the main view*/
    func addARScene(){
        view.addSubview(sceneView)
        startARSession()
        displayARSceneStats()
        setActivatesAutomatically()
        setCoach()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){[self] in
            hideCaptureButtons(animated: true)
        }
    }
    
    /** Remove the Augmented reality scene from the main view and create a new instance of it to release the old memory*/
    func removeARScene(){
        sceneView.session.pause()
        sceneView.removeFromSuperview()
        sceneView = ARSCNView()
        constrainARScene()
    }
    
    /** Constrain the AR Scene's frame to the dimensions of the device*/
    func constrainARScene(){
        DispatchQueue.main.asyncAfter(deadline: .now()){[self] in
            sceneView.frame = contentFrame
        }
    }
    
    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        return sceneView.raycastQuery(from: sceneView.center, allowing: .estimatedPlane, alignment: alignment)
    }
    
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return sceneView.session.raycast(query)
    }
    
    
    
    func addBox(x: Float, y: Float, z: Float){
        let box = SCNBox(width: 0.1, height: 0.1, length: 0.01, chamferRadius: 10)
        
        
        
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        textView.backgroundColor = appThemeColor
        textView.textColor = UIColor.white
        textView.font = .systemFont(ofSize: 12, weight: .light)
        textView.isSelectable = true
        textView.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        textView.clipsToBounds = true
        textView.textAlignment = .center
        textView.isEditable = false
        
        
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        label.backgroundColor = appThemeColor
        label.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
        label.minimumScaleFactor = 0.1
        label.lineBreakMode = .byClipping
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.font = .systemFont(ofSize: 20, weight: .light)
        label.textColor = UIColor.white
        label.clipsToBounds = true
        label.textAlignment = .center
        
        let boxSides = [textView, // front side
                        appThemeColor, // right side
                        appThemeColor, // back side
                        appThemeColor, // left side
                        appThemeColor, // top side
                        appThemeColor] // bottom side
        
        let sideMaterials = boxSides.map { side -> SCNMaterial in
            let material = SCNMaterial()
            material.diffuse.contents = side
            material.locksAmbientWithDiffuse = true
            return material
        }
        box.materials = sideMaterials
        
        let node = SCNTextNode(textView: textView)
        node.geometry = box
        node.position = SCNVector3(x,y,z)
        
        
        /** Orient the box to face the camera*/
        let yawn = sceneView.session.currentFrame?.camera.eulerAngles.y
        node.eulerAngles.y = (yawn ?? 0) + .pi * 2
        node.eulerAngles.x = (sceneView.session.currentFrame?.camera.eulerAngles.x ?? 0)
        
        nodes.append(node)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    
    
    
    //Augmented Reality methods
    
    /** Returns a CGRect that's the size and location of the live video content displayed by the camera*/
    func getContentFrame()->CGRect{
        var frame = CGRect()
        frame = view.bounds
        frame.size.height = frame.size.height - bottomButtonSize
        return frame
    }
    
    /** Button activated logic that triggers a capture event from the output protocol*/
    @objc func takePhoto(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        
        switch augmentedRealityModeEnabled{
        case true:
            return
        case false:
            /** The original brightness of the user's screen, to be restored after a front facing flash*/
            let originalBrightness = UIScreen.main.brightness
            
            switch flashLightOn {
            case true:
                if currentCamera?.position == .back{
                    do{
                        try currentCamera?.lockForConfiguration()
                        currentCamera?.torchMode = .on
                        currentCamera?.unlockForConfiguration()
                    }
                    catch{
                        print("ERROR: Torch could not be used")
                    }
                }
                else{
                    view.addSubview(artificialFlashLight)
                    /** Set the screen's brightness to max to give off maximum luminosity*/
                    UIScreen.main.brightness = CGFloat(1)
                }
            case false:
                if currentCamera?.position == .back{
                    do{
                        try currentCamera?.lockForConfiguration()
                        currentCamera?.torchMode = .off
                        currentCamera?.unlockForConfiguration()
                    }
                    catch{
                        print("ERROR: Torch could not be used")
                    }
                }
            }
            
            /** Delay the photo capture a bit to allow the flashlight to be turned on*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25){[self] in
                let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                stillImageOutput.capturePhoto(with: settings, delegate: self)
            }
            
            /** Turn off the flash light*/
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                if currentCamera?.position == .back{
                    do{
                        try currentCamera?.lockForConfiguration()
                        currentCamera?.torchMode = .off
                        currentCamera?.unlockForConfiguration()
                    }
                    catch{
                        print("ERROR: Torch could not be used")
                    }
                }
                else if currentCamera?.position == .front{
                    /** remove the bright view and restore the user's brightness level to the original value it was at*/
                    artificialFlashLight.removeFromSuperview()
                    UIScreen.main.brightness = originalBrightness
                }
            }
        }
    }
    
    /** Generate a bright view to give light to the front facing camera*/
    func artificialFlash()->UIView{
        let brightView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        brightView.backgroundColor = UIColor.white
        return brightView
    }
    
    /** Method gets the image data from the capture event and then parses this into a usable UIImage object*/
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation()else { return }
        
        let image = UIImage(data: imageData)
        let imageView = UIImageView()
        imageView.image = image
        imageView.frame = view.frame
        imageView.contentMode = .scaleAspectFill
        
        view.addSubview(imageView)
        
        processImage(image: image!)
    }
    
    /** Process the UIImage with apple's text recognition API and print this text out to the console
     - Parameters:
     - image: The image being fed to the text recognition API
     - Author: Rubaia A.
     */
    func processImage(image: UIImage){
        
        /**[WRITE YOUR CODE HERE]*/
        
        
        /**
         /**Make a view controller that will display the image alongside the parsed text recieved from the text recognition API*/
         let imageProcessingVC = ImageProcessingViewController()
         imageProcessingVC.presentingVC = self
         
         /** Make the view controller's view the same shape as the button*/
         imageProcessingVC.view.frame = capturePictureButton.frame
         imageProcessingVC.view.layer.cornerRadius = capturePictureButton.layer.cornerRadius
         
         /**Add this view above all of the others including nav bars*/
         UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(imageProcessingVC.view)
         
         /** Animate the circular view moving to the center of the screen and expanding into a view that encompasses the entire screen and then push this view controller's view onto the navigation controller's stack to release the memory held up by the current view controller*/
         UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
         imageProcessingVC.view.frame.origin = CGPoint(x: view.frame.width/2 - imageProcessingVC.view.frame.width/2, y: view.frame.height/2 - imageProcessingVC.view.frame.height/2)
         }
         UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
         imageProcessingVC.view.frame = view.frame
         imageProcessingVC.view.frame.size.height = view.frame.height
         imageProcessingVC.view.frame.size.width = view.frame.width
         imageProcessingVC.view.frame.origin = CGPoint(x: view.frame.width/2 - imageProcessingVC.view.frame.width/2, y: view.frame.height/2 - imageProcessingVC.view.frame.height/2)
         }
         DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
         navigationController?.pushViewController(imageProcessingVC, animated: false)
         }
         */
    }
    
    /** Adds all required gesture recognizers*/
    func addGestureRecognizers(){
        addPanGesture()
        addPinchGesture()
        addSingleTapGesture()
        addDoubleTapGesture()
        view.isExclusiveTouch = true
    }
    
    /** Pan gesture a user does to draw a selection box around a target text which is then converted into a textview displayed on a 3D rectangle in AR that can be resized and disposed of*/
    func addPanGesture(){
        let pan = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        pan.maximumNumberOfTouches = 1
        pan.minimumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
    }
    
    /** Handler for recognizing when the user pans the view*/
    @objc func viewPanned(sender: UIPanGestureRecognizer){
        let location = sender.location(in: view)
        
        if(contentFrame.contains(location) && location.y > (photoARModeSegmentedControl.frame.origin.y + topButtonSize * 1.25) && isTransientViewBeingPresented == false){
            if(sender.state == .began){
                hideBottomNavButtons(animated: true)
                hideZoomFactorButton(animated: true)
                
                selectionBox = UIView(frame: CGRect(x: location.x, y: location.y, width: 1, height: 1))
                selectionBox.addDashedBorder(strokeColor: UIColor.white, fillColor: UIColor.clear, lineWidth: 5, lineDashPattern: [30,10], cornerRadius: 40)
                selectionBox.animateDashedBorder()
                view.addSubview(selectionBox)
            }
            else if(sender.state == .changed){
                selectionBox.frame = CGRect(x: selectionBox.frame.origin.x, y: selectionBox.frame.origin.y, width: (location.x - selectionBox.frame.origin.x), height: (location.y - selectionBox.frame.origin.y))
                selectionBox.updateDashedBorder(cornerRadius: 40)
            }
            else if(sender.state == .ended){
                selectionBox.convertDashedBorderToStraightBorder()
                showSelectionButtons(animated: true)
                //selectionBox.removeFromSuperview()
                //selectionBox = UIView()
            }
        }
        
    }
    
    /** Simply add a UI gesture recognizer that recognizes single taps on the screen to this view controller's view*/
    func addSingleTapGesture(){
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(viewSingleTapped))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(singleTap)
    }
    
    /** Handler for recognizing when the user taps the view one time*/
    @objc func viewSingleTapped(sender: UITapGestureRecognizer){
        
        if(contentFrame.contains(sender.location(in: view)) && !switchCameraButton.frame.contains(sender.location(in: view)) && switchCameraButton.isEnabled == true && isTransientViewBeingPresented == false){
            hapticFeedBack(FeedbackStyle: .soft)
            
            /** Snapchat esque circular fade in fade out animation signals where the user has tapped*/
            let circleView = UIView(frame: CGRect(x: sender.location(in: view).x, y: sender.location(in: view).y, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
            circleView.layer.cornerRadius = circleView.frame.height/2
            circleView.layer.borderWidth = 0.5
            circleView.layer.borderColor = appThemeColor.cgColor
            circleView.backgroundColor = UIColor.clear
            circleView.clipsToBounds = true
            circleView.transform = CGAffineTransform(scaleX: 0, y: 0)
            
            let inscribedCircleView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width * 0.05, height: view.frame.width * 0.05))
            inscribedCircleView.layer.cornerRadius = inscribedCircleView.frame.height/2
            inscribedCircleView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
            inscribedCircleView.transform = CGAffineTransform(scaleX: 0, y: 0)
            circleView.addSubview(inscribedCircleView)
            
            view.addSubview(circleView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                circleView.transform = CGAffineTransform(scaleX: 2, y: 2)
            }
            UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                inscribedCircleView.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                circleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                inscribedCircleView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                inscribedCircleView.alpha = 0
            }
            UIView.animate(withDuration: 0.5, delay: 0.7, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
                circleView.alpha = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){
                circleView.removeFromSuperview()
            }
            
            switch augmentedRealityModeEnabled{
            case true:
                
                let results = self.sceneView.hitTest(sender.location(in: self.sceneView), types: .featurePoint)
                
                
                guard let result = results.first else {
                    return
                }
                
                let translation = result.worldTransform.translation
                
                
                self.addBox(x: translation.x, y: translation.y, z: translation.z)
                
                
                
                
            case false:
                /** Crash inbound if the camera device isn't present and the code below is activated, so just return*/
                guard currentCamera != nil else {
                    return
                }
                
                /** Method for focusing the camera on the point the user touched*/
                /**Configure the device to focus on the focus point*/
                let focusPoint = sender.location(in: view)
                if currentCamera?.position == .back{
                    do {
                        try currentCamera!.lockForConfiguration()
                        currentCamera!.focusPointOfInterest = focusPoint
                        currentCamera!.focusMode = .continuousAutoFocus
                        //currentCamera!.focusMode = .autoFocus
                        //currentCamera!.focusMode = .locked
                        //currentCamera!.exposurePointOfInterest = focusPoint
                        //currentCamera!.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
                        currentCamera!.unlockForConfiguration()
                    }
                    catch {
                        print("Device unavailable for configuration")
                    }
                }
            }
        }
    }
    
    /**Pinch recognizer for zooming in the video preview */
    @objc func pinched(sender: UIPinchGestureRecognizer){
        /** Multiply the zoom factor here with the stored zoom factor (if it exists)*/
        var zoomScale = sender.scale * zoomFactor
        
        /** When the pinch event ends then the stored zoom factor is updated, the minimum value for the zoom factor is 1, if the value goes lower than this then the API will crash*/
        if(sender.state == .ended){
            zoomFactor = zoomScale >= 1 ? zoomScale : 1
        }
        
        /** Crash inbound if the camera device isn't present and the code below is activated, so just return*/
        guard currentCamera != nil else {
            return
        }
        
        do {
            try currentCamera!.lockForConfiguration()
            defer{currentCamera?.unlockForConfiguration()}
            if(zoomScale <= (currentCamera?.activeFormat.videoMaxZoomFactor)! && zoomScale >= 1){
                currentCamera?.videoZoomFactor = zoomScale
                zoomFactorButton.setTitle(String(format: "%.1f", zoomScale)  + "x", for: .normal)
            }
            else if(zoomScale >= (currentCamera?.activeFormat.videoMaxZoomFactor)!){
                zoomScale = (currentCamera?.activeFormat.videoMaxZoomFactor)!
                currentCamera?.videoZoomFactor = zoomScale
                zoomFactorButton.setTitle(String(format: "%.1f", zoomScale)  + "x", for: .normal)
            }
            else if(zoomScale <= 1){
                zoomScale = 1
                currentCamera?.videoZoomFactor = zoomScale
                zoomFactorButton.setTitle(String(format: "%.1f", zoomScale)  + "x", for: .normal)
            }
            else{
                //print("Unable to set video zoom factor: (max \(currentCamera!.activeFormat.videoMaxZoomFactor), asked \(zoomScale))")
            }
        }
        catch {
            print("\(error.localizedDescription)")
        }
    }
    
    /** Reset the zoom level of the camera*/
    func resetZoomLevel(){
        do {
            try currentCamera!.lockForConfiguration()
            defer{currentCamera?.unlockForConfiguration()}
            currentCamera?.videoZoomFactor = 1
            zoomFactor = 1
            zoomFactorButton.setTitle(String(format: "%.1f", zoomFactor) + "x", for: .normal)
        }
        catch {
            print("\(error.localizedDescription)")
        }
    }
    
    /** Add a pinch recognizer in order to allow the user to zoom in on objects in the preview layer*/
    func addPinchGesture(){
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinched))
        view.addGestureRecognizer(pinch)
    }
    
    /** Simply add a UI gesture recognizer that recognizes double taps on the screen to this view controller's view*/
    func addDoubleTapGesture(){
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(viewDoubleTapped))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(doubleTap)
    }
    
    /** Handler for recognizing when the user taps the view two times in a row*/
    @objc func viewDoubleTapped(sender: UITapGestureRecognizer){
        sender.isEnabled = false
        
        /** Delay the pressing of this button, if the user pressed this in rapid sucession they'll block the UI and interrupt the global queue*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            sender.isEnabled = true
        }
        
        switch augmentedRealityModeEnabled{
        case true:
            return
        case false:
            /**Prevent a camera switch from being triggered while a transient view is being presented and the switch camera button is being used, also only register touches inside of the video preview layer and not inside of the switch camera button under any circumstances*/
            if(contentFrame.contains(sender.location(in: view)) && !switchCameraButton.frame.contains(sender.location(in: view)) && switchCameraButton.isEnabled == true && isTransientViewBeingPresented == false){
                hapticFeedBack(FeedbackStyle: .rigid)
                
                /** Animate this button since it does the same operation as the double tap gesture*/
                switchCameraButtonPressed(sender: switchCameraButton)
            }
        }
    }
    
    /** Handler for the switch camera button that triggers the same camera switching operations as the double tap interaction*/
    @objc func switchCameraButtonPressed(sender: UIButton){
        /** Reset the zoom factor or else the previous zoom will be the basis for the zoom on the next device*/
        resetZoomLevel()
        sender.isEnabled = false
        /** Delay the pressing of this button, if the user pressed this in rapid sucession they'll block the UI and interrupt the global queue*/
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){
            sender.isEnabled = true
        }
        
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){
            sender.transform = CGAffineTransform(rotationAngle: .pi)
        }
        
        /** sets the transform to the identity matrix of itself, which inverts the previous transform and allows the transform above to repeat infinitely, essentially resetting the process via linear algebra*/
        sender.transform = .identity
        
        switch augmentedRealityModeEnabled{
        case true:
            return
        case false:
            hapticFeedBack(FeedbackStyle: .rigid)
            switch currentCamera?.position{
            case .front:
                useBackCamera = true
                currentCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
                setCameraView()
                updateCaptureSession()
            case .back:
                useBackCamera = false
                currentCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!
                setCameraView()
                updateCaptureSession()
            default:
                break
            }
        }
    }
    
    /** Update the session of the video preview layer and start running that new capture session*/
    func updateCaptureSession(){
        videoPreviewLayer.session = captureSession
        /** Throw this into the global queue to prevent the UI from freezing up(being blocked)*/
        DispatchQueue.global(qos: .userInitiated).async{[self] in
            captureSession.startRunning()
        }
    }
    
    /** Handler for touch down event on the flash light button, toggles the torch setting of the current capture device*/
    @objc func flashLightButtonPressed(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .medium)
        toggleTorch()
    }
    
    /** Toggle the flash light bool from true to false to enable the flash light usage when taking a photo*/
    func toggleTorch() {
        guard currentCamera != nil else {return}
        
        if currentCamera?.hasTorch == false{
            print("ERROR: Torch is not available for current device")
        }
        
        /** Switch the flashlighton bool and animate the button's image changing and scaling up and down*/
        if flashLightOn == true{
            flashLightOn = false
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){ [self] in
                flashLightButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                flashLightButton.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
            }
            UIView.animate(withDuration: 0.15, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){ [self] in
                flashLightButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
        else if flashLightOn == false{
            flashLightOn = true
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){ [self] in
                flashLightButton.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
                flashLightButton.setImage(UIImage(systemName: "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
            }
            UIView.animate(withDuration: 0.15, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){ [self] in
                flashLightButton.transform = CGAffineTransform(scaleX: 1, y: 1)
            }
        }
    }
    //Logic for viewing capturing and processing images
    
    /** Handler for the segmented control touch down events*/
    @objc func photoARModeSegmentedControlPressed(sender: UISegmentedControl){
        resetZoomLevel()
        switch sender.selectedSegmentIndex{
        case 0:
            augmentedRealityModeEnabled = false
            
            removeARScene()
            
            /** Start up the camera and bring the UI Nav buttons forwards*/
            setCameraView()
            bringNavUIForwards()
            showCaptureButtons(animated: true)
        case 1:
            augmentedRealityModeEnabled = true
            
            /** Remove the video preview layer and then paint the AR Scene to the view and then bring all the nav UI to the front*/
            removeCameraView()
            
            addARScene()
            displayARSceneStats()
            bringNavUIForwards()
        //hideBottomNavButtons(animated: true)
        default:
            break
        }
        savePhotoARModePreference()
    }
    
    /** Removes the current camera view in preparation for the augemented reality scene to be presented*/
    func removeCameraView(){
        videoPreviewLayer.removeFromSuperlayer()
        videoPreviewLayerActive = false
        guard captureSession != nil else {
            return
        }
        captureSession.stopRunning()
    }
    
    /** Brings the navigation UI forwards so that the rest of the content isn't painted on top of it*/
    func bringNavUIForwards(){
        view.bringSubviewToFront(importButton)
        view.bringSubviewToFront(textToSpeechButton)
        view.bringSubviewToFront(pastHistoryButton)
        view.bringSubviewToFront(transcribeSpeechBubbleButton)
        view.bringSubviewToFront(flashLightButton)
        view.bringSubviewToFront(artificialFlashLight)
        view.bringSubviewToFront(switchCameraButton)
        view.bringSubviewToFront(capturePictureButton)
        view.bringSubviewToFront(myProfileButton)
        view.bringSubviewToFront(settingsButton)
        view.bringSubviewToFront(zoomFactorButton)
        view.bringSubviewToFront(photoARModeSegmentedControl)
        view.bringSubviewToFront(radialBorder1)
        view.bringSubviewToFront(radialBorder2)
        view.bringSubviewToFront(radialBorder3)
        view.bringSubviewToFront(cancelSelectionButton)
        view.bringSubviewToFront(confirmSelectionButton)
    }
    
    /** Constructs and sets the positions of the selection buttons for cropping the live video feed for a photo*/
    func setSelectionButtons(){
        selectionButtonSize = view.frame.width/4 - view.frame.width * 0.10
        
        cancelSelectionButton = UIButton(frame: CGRect(x: view.frame.midX - (selectionButtonSize + 15), y: view.frame.maxY - selectionButtonSize * 1.5, width: selectionButtonSize, height: selectionButtonSize))
        cancelSelectionButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        cancelSelectionButton.tintColor = UIColor.red
        cancelSelectionButton.imageView?.contentMode = .scaleAspectFit
        cancelSelectionButton.contentHorizontalAlignment = .center
        cancelSelectionButton.layer.cornerRadius = cancelSelectionButton.frame.height/2
        cancelSelectionButton.layer.shadowColor = UIColor.darkGray.cgColor
        cancelSelectionButton.layer.shadowRadius = 1
        cancelSelectionButton.layer.shadowOpacity = 1
        cancelSelectionButton.clipsToBounds = true
        cancelSelectionButton.layer.masksToBounds = false
        cancelSelectionButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        cancelSelectionButton.layer.shadowPath = UIBezierPath(roundedRect: cancelSelectionButton.bounds, cornerRadius: cancelSelectionButton.layer.cornerRadius).cgPath
        cancelSelectionButton.imageEdgeInsets = UIEdgeInsets(top: cancelSelectionButton.frame.height * 0.25, left: cancelSelectionButton.frame.height * 0.25, bottom: cancelSelectionButton.frame.height * 0.25, right: cancelSelectionButton.frame.height * 0.25)
        cancelSelectionButton.backgroundColor = UIColor.white
        cancelSelectionButton.addTarget(self, action: #selector(selectionButtonPressed), for: .touchDown)
        cancelSelectionButton.tag = 0
        cancelSelectionButton.isExclusiveTouch = true
        
        confirmSelectionButton = UIButton(frame: CGRect(x: view.frame.midX + 15, y: view.frame.maxY - selectionButtonSize * 1.5, width: selectionButtonSize, height: selectionButtonSize))
        confirmSelectionButton.setImage(UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        confirmSelectionButton.tintColor = UIColor.green
        confirmSelectionButton.imageView?.contentMode = .scaleAspectFit
        confirmSelectionButton.contentHorizontalAlignment = .center
        confirmSelectionButton.layer.cornerRadius = confirmSelectionButton.frame.height/2
        confirmSelectionButton.layer.shadowColor = UIColor.darkGray.cgColor
        confirmSelectionButton.layer.shadowRadius = 1
        confirmSelectionButton.layer.shadowOpacity = 1
        confirmSelectionButton.clipsToBounds = true
        confirmSelectionButton.layer.masksToBounds = false
        confirmSelectionButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        confirmSelectionButton.layer.shadowPath = UIBezierPath(roundedRect: confirmSelectionButton.bounds, cornerRadius: confirmSelectionButton.layer.cornerRadius).cgPath
        confirmSelectionButton.imageEdgeInsets = UIEdgeInsets(top: confirmSelectionButton.frame.height * 0.25, left: confirmSelectionButton.frame.height * 0.25, bottom: confirmSelectionButton.frame.height * 0.25, right: confirmSelectionButton.frame.height * 0.25)
        confirmSelectionButton.backgroundColor = UIColor.white
        confirmSelectionButton.addTarget(self, action: #selector(selectionButtonPressed), for: .touchDown)
        confirmSelectionButton.tag = 1
        confirmSelectionButton.isExclusiveTouch = true
        
        view.addSubview(cancelSelectionButton)
        view.addSubview(confirmSelectionButton)
        
        /** Give the UI time to update before animating*/
        DispatchQueue.main.async{ [self] in
            hideSelectionButtons(animated: false)
        }
    }
    
    //Constructor Methods for top and bottom navigation buttons
    /** Create Top navigation buttons*/
    func setTopNavButtons(){
        loadPhotoARModePreference()
        topButtonSize = view.frame.width/4 - view.frame.width * 0.12
        
        photoARModeSegmentedControl.selectedSegmentTintColor = UIColor.white
        photoARModeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        photoARModeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: appThemeColor], for: .selected)
        photoARModeSegmentedControl.frame.origin = CGPoint(x: view.frame.width/2 - photoARModeSegmentedControl.frame.width/2, y: view.safeAreaInsets.top + photoARModeSegmentedControl.frame.height)
        photoARModeSegmentedControl.isExclusiveTouch = true
        photoARModeSegmentedControl.addTarget(self, action: #selector(photoARModeSegmentedControlPressed), for: .valueChanged)
        
        switch augmentedRealityModeEnabled{
        case true:
            photoARModeSegmentedControl.selectedSegmentIndex = 1
        case false:
            photoARModeSegmentedControl.selectedSegmentIndex = 0
        }
        
        view.bringSubviewToFront(photoARModeSegmentedControl)
        
        myProfileButton = UIButton(frame: CGRect(x: view.frame.minX + topButtonSize/4, y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4, width: topButtonSize, height: topButtonSize))
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
        myProfileButton.addTarget(self, action: #selector(topNavButtonPressed), for: .touchDown)
        myProfileButton.tag = 0
        
        settingsButton = UIButton(frame: CGRect(x: view.frame.maxX - (topButtonSize + topButtonSize/4), y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4, width: topButtonSize, height: topButtonSize))
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
        settingsButton.addTarget(self, action: #selector(topNavButtonPressed), for: .touchDown)
        settingsButton.tag = 1
        
        topNavButtons.append(myProfileButton)
        topNavButtons.append(settingsButton)
        
        view.addSubview(myProfileButton)
        view.addSubview(settingsButton)
        
        /** Give the UI time to update before animating*/
        DispatchQueue.main.async { [self] in
            hideTopNavButtons(animated: false)
            hideZoomFactorButton(animated: false)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1){ [self] in
            showTopNavButtons(animated: true)
            showZoomFactorButton(animated: true)
        }
    }
    
    /**Create the zoom factor button and add it to the UIView*/
    func setZoomFactorButton(){
        let buttonSize = view.frame.width/4 - view.frame.width * 0.14
        
        zoomFactorButton = UIButton(frame: CGRect(x: view.frame.midX - buttonSize/2, y: photoARModeSegmentedControl.frame.maxY + 10, width: buttonSize, height: buttonSize))
        
        zoomFactorButton.tintColor = UIColor.white
        zoomFactorButton.setTitle(String(format: "%.1f", zoomFactor) + "x", for: .normal)
        zoomFactorButton.setTitleColor(UIColor.white, for: .normal)
        zoomFactorButton.titleLabel?.adjustsFontSizeToFitWidth = true
        zoomFactorButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)
        zoomFactorButton.contentHorizontalAlignment = .center
        zoomFactorButton.layer.cornerRadius = zoomFactorButton.frame.height/2
        zoomFactorButton.clipsToBounds = true
        zoomFactorButton.backgroundColor = appThemeColor.withAlphaComponent(0.5)
        //zoomFactorButton.addTarget(self, action: #selector(zoomFactorButtonPressed), for: .touchDown)
        /**Mimic of Apple's secondary trigger for their zoom factor button*/
        //zoomFactorButton.addTarget(self, action: #selector(zoomFactorButtonPressed), for: .touchDragInside)
        zoomFactorButton.isExclusiveTouch = true
        
        view.addSubview(zoomFactorButton)
    }
    
    /**Hides the zoom factor button from the user in an animated or non animated fashion*/
    func hideZoomFactorButton(animated:Bool){
        zoomFactorButton.isEnabled = false
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                zoomFactorButton.alpha = 0
            }
        case false:
            zoomFactorButton.alpha = 0
        }
    }
    
    /**Shows the zoom factor button to the user in an animated or non animated fashion*/
    func showZoomFactorButton(animated:Bool){
        zoomFactorButton.isEnabled = true
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0){[self] in
                zoomFactorButton.alpha = 1
            }
        case false:
            zoomFactorButton.alpha = 1
        }
    }
    
    /**Create navigation buttons*/
    func setNavButtons(){
        bottomButtonSize = view.frame.width/4 - view.frame.width * 0.08
        
        importButton = UIButton(frame: CGRect(x: view.frame.midX - (bottomButtonSize + 5), y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
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
        /**Prevent other buttons from being pressed while this button is being pressed*/
        importButton.isExclusiveTouch = true
        
        textToSpeechButton = UIButton(frame: CGRect(x: view.frame.midX + 5, y: view.frame.maxY - bottomButtonSize * 1.5, width: bottomButtonSize, height: bottomButtonSize))
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
        switch flashLightOn{
        case false:
            flashLightButton.setImage(UIImage(systemName: "bolt.slash.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        case true:
            flashLightButton.setImage(UIImage(systemName: "bolt.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        }
        flashLightButton.tintColor = UIColor.white
        flashLightButton.imageView?.contentMode = .scaleAspectFit
        flashLightButton.contentHorizontalAlignment = .center
        flashLightButton.imageEdgeInsets = UIEdgeInsets(top: flashLightButton.frame.height * 0.2, left: flashLightButton.frame.height * 0.2, bottom: flashLightButton.frame.height * 0.2, right: flashLightButton.frame.height * 0.2)
        flashLightButton.backgroundColor = UIColor.clear
        flashLightButton.isExclusiveTouch = true
        flashLightButton.addTarget(self, action: #selector(flashLightButtonPressed), for: .touchDown)
        
        switchCameraButton = UIButton(frame: CGRect(x: view.frame.midX - bottomButtonSize/2, y: importButton.frame.minY - (bottomButtonSize * 1), width: bottomButtonSize, height: bottomButtonSize))
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        switchCameraButton.tintColor = UIColor.white
        switchCameraButton.imageView?.contentMode = .scaleAspectFit
        switchCameraButton.contentHorizontalAlignment = .center
        switchCameraButton.imageEdgeInsets = UIEdgeInsets(top: switchCameraButton.frame.height * 0.2, left: switchCameraButton.frame.height * 0.2, bottom: switchCameraButton.frame.height * 0.2, right: switchCameraButton.frame.height * 0.2)
        switchCameraButton.backgroundColor = UIColor.clear
        switchCameraButton.isExclusiveTouch = true
        switchCameraButton.addTarget(self, action: #selector(switchCameraButtonPressed), for: .touchDown)
        
        capturePictureButton = UIButton(frame: CGRect(x: view.frame.midX - bottomButtonSize/2, y: flashLightButton.frame.minY - (bottomButtonSize), width: (bottomButtonSize), height: (bottomButtonSize)))
        capturePictureButton.setImage(UIImage(systemName: "circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: 100, weight: .regular)), for: .normal)
        capturePictureButton.tintColor = UIColor.white
        capturePictureButton.layer.cornerRadius = capturePictureButton.frame.height/2
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
        
        switchCameraButton.frame.origin.y = capturePictureButton.frame.minY - switchCameraButton.frame.height
        
        /** Give the UI time to update before animating*/
        DispatchQueue.main.async{[self] in
            hideBottomNavButtons(animated: false)
            showBottomNavButtons(animated: true)
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
        view.addSubview(switchCameraButton)
        
        view.addSubview(radialBorder1)
        view.addSubview(radialBorder2)
        view.addSubview(radialBorder3)
        view.addSubview(capturePictureButton)
    }
    //Constructor Methods for top and bottom navigation buttons
    
    //Top and Bottom Navigational Buttons Logic
    /** Action handler for  touch down events on the top navigation buttons*/
    @objc func topNavButtonPressed(sender: UIButton){
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
        /** My Profile Button*/
        case 0:
            let myProfileView = MyProfileView(presentingVC: self)
            presentationInProgress()
            
            /** Make the view controller's view the same shape as the button*/
            myProfileView.frame = sender.frame
            myProfileView.layer.cornerRadius = sender.layer.cornerRadius
            myProfileView.clipsToBounds = true
            
            myProfileView.setOriginalSize(frame: sender.frame)
            myProfileView.setOriginalLocation(point: sender.frame.origin)
            
            /**Add this view above all of the others including nav bars*/
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(myProfileView)
            
            /** Animate the circular view moving to the center of the screen and expanding into a view that encompasses the entire screen and then push this view controller's view onto the navigation controller's stack to release the memory held up by the current view controller*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                myProfileView.frame.origin = CGPoint(x: view.frame.width/2 - myProfileView.frame.width/2, y: view.frame.height/2 - myProfileView.frame.height/2)
            }
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                myProfileView.frame = view.frame
                myProfileView.frame.size.height = view.frame.height * 0.9
                myProfileView.frame.size.width = view.frame.width * 0.9
                myProfileView.frame.origin = CGPoint(x: view.frame.width/2 - myProfileView.frame.width/2, y: view.frame.height/2 - myProfileView.frame.height/2)
            }
        /** Settings Button*/
        case 1:
            let settingsView = SettingsView(presentingVC: self)
            presentationInProgress()
            
            /** Make the view controller's view the same shape as the button*/
            settingsView.frame = sender.frame
            settingsView.layer.cornerRadius = sender.layer.cornerRadius
            settingsView.clipsToBounds = true
            
            settingsView.setOriginalSize(frame: sender.frame)
            settingsView.setOriginalLocation(point: sender.frame.origin)
            
            /**Add this view above all of the others including nav bars*/
            UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(settingsView)
            
            /** Animate the circular view moving to the center of the screen and expanding into a view that encompasses the entire screen and then push this view controller's view onto the navigation controller's stack to release the memory held up by the current view controller*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                settingsView.frame.origin = CGPoint(x: view.frame.width/2 - settingsView.frame.width/2, y: view.frame.height/2 - settingsView.frame.height/2)
            }
            UIView.animate(withDuration: 0.5, delay: 0.5, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                settingsView.frame = view.frame
                settingsView.frame.size.height = view.frame.height * 0.9
                settingsView.frame.size.width = view.frame.width * 0.9
                settingsView.frame.origin = CGPoint(x: view.frame.width/2 - settingsView.frame.width/2, y: view.frame.height/2 - settingsView.frame.height/2)
            }
        default:
            return
        }
    }
    
    /**When a transient / impermanent view is being presented then blur the background*/
    func presentationInProgress(){
        isTransientViewBeingPresented = true
        /**Add a blurred view to inform the user that the current focus is solely on the presented view*/
        view.addSubview(blurredView)
        switch augmentedRealityModeEnabled{
        case true:
            sceneView.session.pause()
        case false:
            break
        }
    }
    
    /**Notification another view or view controller can send to this view controller notifying it of the presentation of its content being complete*/
    func presentationComplete(){
        /** Remove the blurred view as the focus is now back on this view controller's content*/
        blurredView.removeFromSuperview()
        isTransientViewBeingPresented = false
        switch augmentedRealityModeEnabled{
        case true:
            startARSession()
        case false:
            break
        }
    }
    
    /** Action handler for  touch down events on the selection buttons*/
    @objc func selectionButtonPressed(sender: UIButton){
        hapticFeedBack(FeedbackStyle: .rigid)
        
        /** Prevent the user from triggering the button in rapid succession*/
        sender.isEnabled = false
        
        /** Make the view slightly transparent and scale it down followed by immediately undoing said transforms and alpha changes*/
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            let scale = CGAffineTransform(scaleX: 0.8, y: 0.8)
            let translate = CGAffineTransform(translationX: 0, y: -20)
            sender.transform = scale.concatenating(translate)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            let translate = CGAffineTransform(translationX: 0, y: 0)
            sender.transform = scale.concatenating(translate)
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
        
        switch sender.tag {
        //Cancel the selection box
        case 0:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                selectionBox.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){[self] in
                selectionBox.removeFromSuperview()
                hideSelectionButtons(animated: true)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
                showBottomNavButtons(animated: true)
            }
        //Confirm the selection box
        case 1:
            selectionBox.removeFromSuperview()
            hideSelectionButtons(animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                showBottomNavButtons(animated: true)
            }
        default:
            return
        }
    }
    
    /** Action handler for  touch down events on the bottom navigation buttons*/
    @objc func bottomNavButtonPressed(sender: UIButton){
        /** Give the user a nice touch based reward for tapping the button*/
        hapticFeedBack(FeedbackStyle: .rigid)
        
        /** Prevent the user from triggering the button in rapid succession*/
        sender.isEnabled = false
        
        /** Make the view slightly transparent and scale it down followed by immediately undoing said transforms and alpha changes*/
        UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            let scale = CGAffineTransform(scaleX: 0.8, y: 0.8)
            let translate = CGAffineTransform(translationX: 0, y: -20)
            sender.transform = scale.concatenating(translate)
        }
        UIView.animate(withDuration: 0.25, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn, .allowUserInteraction]){
            let scale = CGAffineTransform(scaleX: 1, y: 1)
            let translate = CGAffineTransform(translationX: 0, y: 0)
            sender.transform = scale.concatenating(translate)
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
            /** After importing an image from the user's photo album feed this image to the process image method*/
            //processImage(image: nil)
            break
        /** Text To Speech Button*/
        case 1:
            break
        /** Past History Button triggers a custom segue*/
        case 2:
            let pastHistoryVC = PastHistoryViewController()
            pastHistoryVC.presentingVC = self
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                presentationInProgress()
            }
            
            /** Make the view controller's view the same shape as the button*/
            pastHistoryVC.view.frame = sender.frame
            pastHistoryVC.view.layer.cornerRadius = sender.layer.cornerRadius
            
            /** Add the view controller's view to the current view controller's view as a subview*/
            view.addSubview(pastHistoryVC.view)
            
            /** Animate the circular view moving to the center of the screen and expanding into a view that encompasses the entire screen and then push this view controller's view onto the navigation controller's stack to release the memory held up by the current view controller*/
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                pastHistoryVC.view.frame.origin = CGPoint(x: view.frame.width/2 - pastHistoryVC.view.frame.width/2, y: view.frame.maxY + 100)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){[self] in
                navigationController?.present(pastHistoryVC, animated: true)
            }
            
        /** Transcribe Speech Bubble Button*/
        case 3:
            break
        default:
            return
        }
    }
    
    /** Hides selection buttons statically or in an animated manner*/
    func hideSelectionButtons(animated:Bool){
        cancelSelectionButton.isEnabled = false
        confirmSelectionButton.isEnabled = false
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                cancelSelectionButton.frame.origin = CGPoint(x: view.frame.midX - (selectionButtonSize + 15), y: view.frame.maxY + selectionButtonSize * 5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                confirmSelectionButton.frame.origin = CGPoint(x: view.frame.midX + 15, y: view.frame.maxY + selectionButtonSize * 5)
            }
        case false:
            cancelSelectionButton.frame.origin = CGPoint(x: view.frame.midX - (selectionButtonSize + 15), y: view.frame.maxY + selectionButtonSize * 5)
            confirmSelectionButton.frame.origin = CGPoint(x: view.frame.midX + 15, y: view.frame.maxY + selectionButtonSize * 5)
        }
    }
    
    /** Shows selection buttons statically or in an animated manner*/
    func showSelectionButtons(animated:Bool){
        cancelSelectionButton.isEnabled = true
        confirmSelectionButton.isEnabled = true
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                cancelSelectionButton.frame.origin = CGPoint(x: view.frame.midX - (selectionButtonSize + 15), y: view.frame.maxY - selectionButtonSize * 1.5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                confirmSelectionButton.frame.origin = CGPoint(x: view.frame.midX + 15, y: view.frame.maxY - selectionButtonSize * 1.5)
            }
        case false:
            cancelSelectionButton.frame.origin = CGPoint(x: view.frame.midX - (selectionButtonSize + 15), y: view.frame.maxY - selectionButtonSize * 1.5)
            confirmSelectionButton.frame.origin = CGPoint(x: view.frame.midX + 15, y: view.frame.maxY - selectionButtonSize * 1.5)
        }
    }
    
    /** Shows capture buttons and associated views statically or in an animated manner*/
    func showCaptureButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 1){[self] in
                flashLightButton.alpha = 1
                switchCameraButton.alpha = 1
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
            switchCameraButton.alpha = 1
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
                switchCameraButton.alpha = 0
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
            switchCameraButton.alpha = 0
            capturePictureButton.transform = CGAffineTransform(scaleX: 0, y: 0)
            radialBorder1.alpha =  0
            radialBorder2.alpha = 0
            radialBorder3.alpha = 0
        }
    }
    
    /** Hide bottom navigation buttons in a static or animated manner*/
    func hideBottomNavButtons(animated: Bool){
        bottomNavButtons[0].isEnabled = false
        bottomNavButtons[1].isEnabled = false
        bottomNavButtons[2].isEnabled = false
        bottomNavButtons[3].isEnabled = false
        
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY + bottomButtonSize * 5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - (bottomButtonSize + 5), y: view.frame.maxY + bottomButtonSize * 5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 5, y: view.frame.maxY + bottomButtonSize * 5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY + bottomButtonSize * 5)
            }
        case false:
            bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY + bottomButtonSize * 5)
            bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - (bottomButtonSize + 5), y: view.frame.maxY + bottomButtonSize * 5)
            bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 5, y: view.frame.maxY + bottomButtonSize * 5)
            bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY + bottomButtonSize * 5)
        }
    }
    
    /** Display bottom navigation buttons in a static or animated manner*/
    func showBottomNavButtons(animated: Bool){
        switch animated {
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - (bottomButtonSize + 5), y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.4, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 5, y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            UIView.animate(withDuration: 0.5, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY - bottomButtonSize * 1.5)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
                bottomNavButtons[0].isEnabled = true
                bottomNavButtons[1].isEnabled = true
                bottomNavButtons[2].isEnabled = true
                bottomNavButtons[3].isEnabled = true
            }
        case false:
            bottomNavButtons[0].frame.origin = CGPoint(x: importButton.frame.minX - (bottomButtonSize + 10), y: view.frame.maxY - bottomButtonSize * 1.5)
            bottomNavButtons[1].frame.origin = CGPoint(x: view.frame.midX - (bottomButtonSize + 5), y: view.frame.maxY - bottomButtonSize * 1.5)
            bottomNavButtons[2].frame.origin = CGPoint(x: view.frame.midX + 5, y: view.frame.maxY - bottomButtonSize * 1.5)
            bottomNavButtons[3].frame.origin = CGPoint(x: textToSpeechButton.frame.maxX + (10), y: view.frame.maxY - bottomButtonSize * 1.5)
            bottomNavButtons[0].isEnabled = true
            bottomNavButtons[1].isEnabled = true
            bottomNavButtons[2].isEnabled = true
            bottomNavButtons[3].isEnabled = true
        }
    }
    
    /** Hide top navigation buttons in a static or animated manner*/
    func hideTopNavButtons(animated: Bool){
        topNavButtons[0].isEnabled = false
        topNavButtons[1].isEnabled = false
        
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                topNavButtons[0].frame.origin = CGPoint(x: view.frame.minX - topButtonSize * 2, y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            }
            UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                topNavButtons[1].frame.origin = CGPoint(x: view.frame.maxX + (topButtonSize * 4), y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            }
        case false:
            topNavButtons[0].frame.origin = CGPoint(x: view.frame.minX - topButtonSize * 2, y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            topNavButtons[1].frame.origin = CGPoint(x: view.frame.maxX + (topButtonSize * 4), y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
        }
    }
    
    /** Display top navigation buttons in a static or animated manner*/
    func showTopNavButtons(animated: Bool){
        switch animated{
        case true:
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                topNavButtons[0].frame.origin = CGPoint(x: view.frame.minX + topButtonSize/4, y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            }
            UIView.animate(withDuration: 0.5, delay: 0.25, usingSpringWithDamping: 0.7, initialSpringVelocity: 1, options: [.curveEaseIn]){[self] in
                topNavButtons[1].frame.origin = CGPoint(x: view.frame.maxX - (topButtonSize + topButtonSize/4), y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1){[self] in
                topNavButtons[0].isEnabled = true
                topNavButtons[1].isEnabled = true
            }
        case false:
            topNavButtons[0].frame.origin = CGPoint(x: view.frame.minX + topButtonSize/4, y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            topNavButtons[1].frame.origin = CGPoint(x: view.frame.maxX - (topButtonSize + topButtonSize/4), y: photoARModeSegmentedControl.frame.origin.y + topButtonSize/4)
            topNavButtons[0].isEnabled = true
            topNavButtons[1].isEnabled = true
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
    //Top and Bottom Navigational Buttons Logic
}

