//
//  ViewController.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/17/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit
import AVFoundation

let menuCellIdentifier="rotationCell"
let viewCellIdentifier="collectionCell"
let QUEUE_NAME = "com.lambton.FinalNoteTaking"

var images = [UIImage]()

class ViewController: UIViewController, UITextViewDelegate, UITableViewDelegate, UITableViewDataSource, YALContextMenuTableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, MKMapViewDelegate, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var menuTitles : [String?] = []
    var menuIcons : [UIImage?] = []
    var contextMenuTableView: YALContextMenuTableView?
    
    var locationManager = CLLocationManager()
    var myPosition = CLLocationCoordinate2D()
    var progressView:UIProgressView?
    var progressLabel:UILabel?
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var tvNote: UITextView!
    //var tvNote:UITextView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    //var imageView:   View!
    
    @IBOutlet weak var toolbarBottom: UIToolbar!
    
    
    @IBOutlet weak var btnRecordStart: UIBarButtonItem!
    
    @IBOutlet weak var btnRecordPlay: UIBarButtonItem!
    
    
    @IBOutlet weak var btnRecordPause: UIBarButtonItem!
    
    @IBOutlet weak var btnRecordExit: UIBarButtonItem!
    
    @IBOutlet weak var lblTime: UIBarButtonItem!
    
    @IBOutlet weak var sliderTime: UISlider!
    let imagePicker:UIImagePickerController! = UIImagePickerController()
    var curNote : Note? = nil
    var newQueue:dispatch_queue_t?
    
    var keyboardHeight:CGFloat = 0.0
    var audioPlayer:AVAudioPlayer?
    var audioRecorder:AVAudioRecorder?
    var recordingSession:AVAudioSession?
    var audioURL:NSURL?
    var audioName:String?
    var timeTimer:NSTimer?
    var milliseconds: Int = 0
    override func viewDidLoad() {
        NSLog("viewDidLoad")
        super.viewDidLoad()
        
        images = [UIImage]()
        if (newQueue == nil) {
            newQueue = dispatch_queue_create(QUEUE_NAME, nil)
        }
        mapView.delegate = self
        self.addControls()
        if Reachability.isConnectedToNetwork() {
            self.progressView!.hidden = false
            self.progressView!.progress = 0.0
            self.progressLabel!.text = NSLocalizedString("Location Processing...", comment: "Location Processing...")
        } else {
            Util.showAlertOK("No Internet", msg: "Network connection Failed", view: self)
            self.progressView!.hidden = true
        }
        
        dispatch_async(newQueue!){
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
            self.locationManager.startUpdatingLocation()
        }
        if curNote != nil {
            self.tvNote.text = self.curNote!.noteText
            
            let arrImage = self.curNote!.image.componentsSeparatedByString(";")
            for var i = 0; i < arrImage.count-1; i++ {
                let imagePath = Util.getPath(arrImage[i])
                let image = UIImage(contentsOfFile: imagePath)
                images.append(image!)
            }
            if self.curNote!.audio != ""
            {
                self.audioName = self.curNote!.audio
            }
            dispatch_async(newQueue!){
                let curCoord = CLLocationCoordinate2D(latitude: self.curNote!.latitude, longitude: self.curNote!.longitude)
                let annotation = MKPointAnnotation()
                annotation.title = "This notes was taken in here"
                annotation.coordinate = curCoord
                self.mapView.addAnnotation(annotation)
                NSLog("Annotation......")
                let span = MKCoordinateSpanMake(0.05, 0.05)
                let region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(self.curNote!.latitude, self.curNote!.longitude), span: span)
                dispatch_async(dispatch_get_main_queue()){
                    self.mapView.setRegion(region, animated: true)
                    self.mapView.showsUserLocation = false
                }
            }
        } else {
           // tvNote = UITextView(frame: CGRectMake(10, 50, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height/2))
            tvNote.delegate = self
            tvNote.text = "Input Text"
            tvNote.textColor = UIColor.lightGrayColor()
           
        }
        
        self.initiateMenuOptions()
        imagePicker.delegate = self
        
        ////
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            
        } catch let error as NSError {
            NSLog("AVAudioSession Error : \(error)")
        }
        
        if let fileName = audioName {
            audioURL = NSURL(fileURLWithPath: Util.getPath(fileName))
            //audioURL = NSURL(string: "/Users/hyunjukoo/Documents/IELTS/Hackers/01 First Step 1.mp3")
            do {
                try audioPlayer = AVAudioPlayer(contentsOfURL: audioURL!)
            }
            catch let error as NSError {
                NSLog("AVAudioPlayer error: \(error)")
            }
            audioPlayer?.delegate = self
            toolbarBottom.hidden = false
            btnRecordStart.image = UIImage(named: "RecordIcon")
            btnRecordStart.enabled = false
            btnRecordPlay.enabled = true
            btnRecordPause.enabled = false
            lblTime.title = Util.stringFromTimeInterval((audioPlayer?.duration)!)
            sliderTime.hidden = true
            
        } else {
             toolbarBottom.hidden = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        NSLog("viewDidLayoutSubviews")
        var newFrame = tvNote.frame
        if images.count > 0 {
            newFrame.origin.y = 180
        } else {
            newFrame.origin.y = 50
        }
        tvNote.frame = newFrame
        NSLog("toolbarBottom.hidden = \(toolbarBottom.hidden)")
        if toolbarBottom.hidden == false {
            var newFrame1 = toolbarBottom.frame
            newFrame1.origin.y = toolbarBottom.frame.origin.y - keyboardHeight
            //newFrame1.origin.y = 205
            toolbarBottom.frame = newFrame1
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")
        collectionView.reloadData()
        self.registerForKeyboardNotifications()
        
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "stopRecording:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func addControls(){
        progressView = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
        progressView?.center = self.view.center
        view.addSubview(progressView!)
        
        progressLabel = UILabel()
        let frame = CGRectMake(view.center.x - 80, view.center.y - 50, 300, 50)
        progressLabel?.frame = frame
        view.addSubview(progressLabel!)
    }
    
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        NSLog("Got Location \(newLocation.coordinate.latitude), \(newLocation.coordinate.longitude)")
        dispatch_async(newQueue!){
            self.locationManager.stopUpdatingLocation()
            
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: newLocation.coordinate, span: span)
            
            self.mapView.setRegion(region, animated: true)
            self.myPosition = newLocation.coordinate
            dispatch_async(dispatch_get_main_queue()){
                self.progressView!.progress = 0.25
            }
        }
//        progressLabel!.text = NSLocalizedString("Reverse Geocoding Location", comment: "Reverse Geocoding Location")
        //progressView!.hidden = true
        //progressLabel!.text = ""
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        progressView!.hidden = true
        progressLabel!.text = ""
        Util.showAlertOK("Error while updating location", msg: error.localizedDescription, view: self)
    }
    
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSLog("mapView regionDidChangeAnimated")
        self.progressView!.progress = 0.5
    }
    
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        self.progressView!.progress = 0.75
    
    }
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {
        self.progressView!.hidden = true
        self.progressLabel!.text = ""
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        self.contextMenuTableView!.reloadData()
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willRotateToInterfaceOrientation(toInterfaceOrientation, duration:duration)
        
        self.contextMenuTableView!.updateAlongsideRotation()
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        coordinator.animateAlongsideTransition(nil, completion: {(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.contextMenuTableView!.reloadData()
        })
        
        self.contextMenuTableView!.updateAlongsideRotation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if tvNote.textColor == UIColor.lightGrayColor() {
            tvNote.text = ""
            tvNote.textColor = UIColor.blackColor()
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if tvNote.text == "" {
            tvNote.text = "Input text"
            tvNote.textColor = UIColor.lightGrayColor()
        }
    }
    
    @IBAction func backgroundTouchDown(sender: UIControl) {
        tvNote.resignFirstResponder()
    }
    
    @IBAction func btnSave(sender: AnyObject) {
        //Update Item
        if curNote != nil {
            //dispatch_async(newQueue!) {
                let note:Note = self.curNote!
                note.noteText = self.tvNote.text!
                note.dateModified = Util.formattedCurrentDate()
                note.image = self.saveImages()
                if let _ = audioPlayer {
                    note.audio = self.audioName!
                } else {
                    note.audio = ""
                }
                let result = ModelManager.getInstance().updateNote(note)
                //dispatch_async(dispatch_get_main_queue()){
                    if result {
                        NSLog("Record updated successfully")
                        self.dismissView()
                    } else {
                        NSLog("Error in updating record")
                    }
                //}
            //}
         } else { //Insert a new Item
            let imagePaths = self.saveImages()
            let note:Note = Note()
            note.noteText = self.tvNote.text!
            note.dateCreated = Util.formattedCurrentDate()
            note.dateModified = Util.formattedCurrentDate()
            note.latitude = self.myPosition.latitude
            note.longitude = self.myPosition.longitude
            note.image = imagePaths
            if audioPlayer != nil {
                note.audio = self.audioName!
            }
            let result = ModelManager.getInstance().addNote(note)
        
            if result {
                NSLog("Record inserted sucessfully")
                self.dismissView()
            } else {
                NSLog("Error in inserting record")
            }
        }
    }
    
    @IBAction func btnCancel(sender: AnyObject) {
        dismissView()
    }
    
    func dismissView(){
        cleanupAudio()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func saveImages() -> String{
        var names = ""
        for var i = 0 ; i<images.count; i++ {
            let data = UIImagePNGRepresentation(images[i])!
            let imageName = Util.getCurrentDate().stringByAppendingString(String(i)).stringByAppendingString(".png")
            
            names = names.stringByAppendingString(imageName).stringByAppendingString(";")
            let fileName = Util.getPath(imageName)
            data.writeToFile(fileName, atomically: true)
        }
        return names
    }
    
    @IBAction func btnAdd(sender: AnyObject) {
        // init YALContextMenuTableView tableView
        self.contextMenuTableView = YALContextMenuTableView(tableViewDelegateDataSource: self)
        self.contextMenuTableView!.animationDuration = 0.11;
        //optional - implement custom YALContextMenuTableView custom protocol
        self.contextMenuTableView!.yalDelegate = self
        let cellNib = UINib(nibName: "ContextMenuCell", bundle: nil)
        self.contextMenuTableView?.registerNib(cellNib, forCellReuseIdentifier: menuCellIdentifier)
        
        // it is better to use this method only for proper animation
        self.contextMenuTableView?.showInView(self.navigationController!.view, withEdgeInsets: UIEdgeInsetsZero, animated: true)
    }
    
    func contextMenuTableView(contextMenuTableView: YALContextMenuTableView!, didDismissWithIndexPath indexPath: NSIndexPath!) {
        print("Menu dismissed with indexpath = \(indexPath.row)")
        
        switch indexPath.row {
        case 1 :
                takePicture()
        case 2 :
                photoFromLibrary()
        case 3 :
                recordAudio()
        default:break
            
        }
        
    }
    
    func takePicture(){
        if(UIImagePickerController.isSourceTypeAvailable(.Camera)){
            if UIImagePickerController.availableCaptureModesForCameraDevice(.Rear) != nil {
                imagePicker.allowsEditing = false
                imagePicker.sourceType = .Camera
                imagePicker.cameraCaptureMode = .Photo
                presentViewController(imagePicker, animated: true, completion: nil)
            }else{
                Util.showAlertOK("Rear camera doesn't exit", msg: "Application cannot access the rear camera", view: self)
            }
        } else {
            Util.showAlertOK("Camera inaccessable", msg: "Application cannot access the camera.", view:self)
            
        }
    }
    
    func photoFromLibrary(){
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .PhotoLibrary
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func recordAudio(){
        if let _ = audioPlayer {
            Util.showAlertOK("Voice Memo", msg: "This note has already a voice memo", view:self)
            return
        }
        NSLog("Record Audio")
        NSLog("toolbarBottom.hidden = \(toolbarBottom.hidden)")
        toolbarBottom.hidden = false
        
        var newFrameMapView = mapView.frame
        newFrameMapView.origin.y = mapView.frame.origin.y - toolbarBottom.frame.height
        mapView.frame = newFrameMapView
        NSLog("toolbarBottom.hidden = \(toolbarBottom.hidden)")
        
        if keyboardHeight > 0 {
            var newFrame1 = toolbarBottom.frame
            newFrame1.origin.y = UIScreen.mainScreen().bounds.height - keyboardHeight - toolbarBottom.frame.height
            //newFrame1.origin.y = 205
            toolbarBottom.frame = newFrame1
        }
        btnRecordStart.image = UIImage(named: "RecordIcon")
        btnRecordStart.enabled = true
        btnRecordPlay.enabled = false
        btnRecordPause.enabled = false
        lblTime.title = "00:00:00"
        sliderTime.hidden = true
        
        //////////
        audioName = Util.getCurrentDate().stringByAppendingString(".aac")
        audioURL = NSURL(fileURLWithPath: Util.getPath(audioName!))
    
        let settings = [AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC), AVSampleRateKey: NSNumber(integer: 44100), AVNumberOfChannelsKey: NSNumber(integer: 2)]
        try! audioRecorder = AVAudioRecorder(URL: audioURL!, settings: settings)
        audioRecorder!.delegate = self
        audioRecorder!.prepareToRecord()
    }

    func initToolbarBottom(){
    
    }
    func selectAudio(){
        Util.showAlertOK("Select Audio", msg: "It will be in version2", view:self)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        NSLog("Got an image")
        let pickedImage:UIImage = (info[UIImagePickerControllerOriginalImage]) as! UIImage
        //pickedImage.drawInRect(CGRectMake(0, 0, 200, 200))
        
        //imageView.contentMode = .ScaleAspectFit
        //imageView.image = pickedImage
        
//        let attachment = NSTextAttachment()
//        attachment.image = pickedImage
//        attachment.bounds = CGRectMake(0,0,200, 150)
//        
//        let attString = NSAttributedString(attachment: attachment)
//        
//        tvNote.textStorage.insertAttributedString(attString, atIndex: tvNote.selectedRange.location)
        images.append(pickedImage)
        //images.insert(pickedImage, atIndex: 0)
        
        collectionView.reloadData()
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        NSLog("User canceled image")
        dismissViewControllerAnimated(true, completion: nil)
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let t = tableView as! YALContextMenuTableView
        t.dismisWithIndexPath(indexPath)
        
    }
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.menuTitles.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let t = tableView as! YALContextMenuTableView
        let cell = t.dequeueReusableCellWithIdentifier(menuCellIdentifier, forIndexPath:indexPath) as! ContextMenuCell
        
        cell.backgroundColor = UIColor.clearColor()
        cell.menuTitleLabel.text = self.menuTitles[indexPath.row]
        cell.menuImageView.image = self.menuIcons[indexPath.row]
        
        
        return cell;
        
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(viewCellIdentifier, forIndexPath:indexPath) as! PickerImageCell
        
        //imageView = UIImageView(image: images[indexPath.item])
        //cell.addSubview(imageView)
        //cell.backgroundColor = UIColor.grayColor()
        //cell.backgroundColor = UIColor(red: 0, green: 191, blue: 255, alpha: 1)
        cell.imageView.image = images[indexPath.item]
        
        return cell;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize{

        var cellSize = CGSizeZero
        
        cellSize.height = 120
        
        if(images.count == 1)
        {
            cellSize.width = self.view.bounds.size.width - 20;
            
        }
        else if(images.count == 2)
        {
            cellSize.width = self.view.bounds.size.width / 2 - 10;
        }
        else
        {
            cellSize.width = self.view.bounds.size.width / 3;
        }
        
        return cellSize;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat{
        return 1.0
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UICollectionViewCell
        let indexPath = collectionView.indexPathForCell(cell)
        let detailViewController:DetailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.detailImage = images[indexPath!.row]
        detailViewController.detailImageIdx = indexPath!.row
    }

    func initiateMenuOptions() {
        self.menuTitles = ["",
            "Take Picture",
            "Select Image",
            "Voice Memo"]
        
       self.menuIcons = [UIImage(named: "Icnclose"), UIImage(named: "CameraIcon"), UIImage(named: "GalleryIcon"), UIImage(named: "RecordIcon")]
        
    }
    
    func registerForKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillAppear:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"keyboardWillDisappear:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillAppear(notification: NSNotification){
        NSLog("keyboardWillAppear")
        let keyboardSize:CGSize = (notification.userInfo! as NSDictionary)
            .objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        keyboardHeight = keyboardSize.height
    }
    
    func keyboardWillDisappear(notification: NSNotification){
        NSLog("keyboardWillDisapper")
        keyboardHeight = 0
        let keyboardSize:CGSize = (notification.userInfo! as NSDictionary)
            .objectForKey(UIKeyboardFrameBeginUserInfoKey)!.CGRectValue.size
        
        if toolbarBottom.hidden == false {
            var newFrame1 = toolbarBottom.frame
            newFrame1.origin.y = toolbarBottom.frame.origin.y + keyboardSize.height
            toolbarBottom.frame = newFrame1
            
            var newFrameMapView = mapView.frame
            newFrameMapView.origin.y = UIScreen.mainScreen().bounds.height - mapView.frame.height - toolbarBottom.frame.height - 5
            mapView.frame = newFrameMapView
        }
    }

    @IBAction func btnRecordStop(sender: UIBarButtonItem) {
        if btnRecordPlay.enabled || btnRecordPause.enabled {
            let alert=UIAlertController(title: "Delete", message: "Voice memo will be deleted", preferredStyle: UIAlertControllerStyle.Alert);
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil));
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: {(action:UIAlertAction) in
                if let _ = self.audioRecorder {
                    if self.audioRecorder!.recording {
                        self.audioRecorder!.stop()
                    }
                    self.audioRecorder!.deleteRecording()
                }
                self.removeToolBarBottom()
                self.cleanupAudio()
                
            }));
            presentViewController(alert, animated: true, completion: nil);
        }else {
            self.removeToolBarBottom()
        }
        
        
     }
    
    func removeToolBarBottom(){
        self.toolbarBottom.hidden = true
        
        var newFrame1 = self.toolbarBottom.frame
        newFrame1.origin.y =  UIScreen.mainScreen().bounds.height - self.toolbarBottom.frame.height
        self.toolbarBottom.frame = newFrame1
        
        var newFrameMapView = self.mapView.frame
        newFrameMapView.origin.y = UIScreen.mainScreen().bounds.height - self.mapView.frame.height - 5
        self.mapView.frame = newFrameMapView
    }
    
    @IBAction func btnRecordStart(sender: AnyObject) {
        timeTimer?.invalidate()
        //NSLog("recording = \(audioRecorder!.recording)")
        if let _ = audioRecorder {
            if audioRecorder!.recording {
                audioRecorder!.stop()
            } else {
                milliseconds = 0
                lblTime.title = "00:00:00"
                timeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "updateTimeLabel:", userInfo: nil, repeats: true)
                //audioRecorder!.deleteRecording()
                audioRecorder!.record()
            }
        }
        
        btnRecordStart.image = audioRecorder!.recording ? UIImage(named: "VoiceStopIcon") : UIImage(named: "RecordIcon")
    }
    
    
    @IBAction func btnRecordPlay(sender: AnyObject) {
        if let player = audioPlayer {
            player.play()
            
            sliderTime.hidden = false
            sliderTime.minimumValue = 0
            sliderTime.maximumValue = Float(player.duration)
        }

        btnRecordPlay.enabled = false
        btnRecordPause.enabled = true
        
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("updateSlider"), userInfo: nil, repeats: true)
        
    }
    
    
    @IBAction func btnPlayPause(sender: AnyObject) {
        if let _ = audioPlayer {
            if audioPlayer!.playing {
                audioPlayer!.stop()
            } else {
                audioPlayer!.play()
            }
        }
        //cleanup()
//        if let player = audioPlayer {
//            player.stop()
//        }
        //btnRecordPause.enabled = false
        //btnRecordPlay.enabled = true
    }
    
    func updateTimeLabel(timer: NSTimer) {
        milliseconds++
        let milli = (milliseconds % 60)
        let sec = (milliseconds / 60) % 60
        let min = milliseconds / 3600
        lblTime.title = NSString(format: "%02d:%02d:%02d", min, sec, milli) as String
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        if let _ = audioPlayer {
            btnRecordPlay.enabled = true
            btnRecordPause.enabled = false
        }
        //self.audioPlayer = nil
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        NSLog("audioRecorderDidFinishRecording")
        self.btnRecordStart.enabled = false
        self.btnRecordPlay.enabled = true
        
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: audioURL!)
        }
        catch let error as NSError {
            NSLog("error: \(error)")
        }
        audioPlayer?.delegate = self
    }
    
    
//    func stopRecording(sender: AnyObject) {
//        if audioRecorder!.recording {
//            btnRecordStart(sender)
//        }
//    }
    
    func cleanupAudio() {
        NSLog("cleanup")
        timeTimer?.invalidate()
        if let _ = audioRecorder {
            if audioRecorder!.recording {
                audioRecorder!.stop()
                audioRecorder!.deleteRecording()
            }
        }
        if let player = audioPlayer {
            player.stop()
        }
        self.audioPlayer = nil
    }
    
    @IBAction func slideValueChanged(sender: AnyObject) {
        if let _ = audioPlayer {
            audioPlayer!.stop()
            audioPlayer!.currentTime = NSTimeInterval(sliderTime.value)
            audioPlayer!.prepareToPlay()
            audioPlayer!.play()
        }
        
        btnRecordPlay.enabled = false
        btnRecordPause.enabled = true
    }
    
    func updateSlider(){
        if let player = audioPlayer {
            sliderTime.value = Float(player.currentTime)
        }
    }
}

