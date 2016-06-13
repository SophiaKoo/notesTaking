//
//  Util.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/17/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import UIKit

class Util {
    class func getPath(fileName: String) -> String {
        
        let documentsURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let fileURL = documentsURL.URLByAppendingPathComponent(fileName)
        
        return fileURL.path!
    }
    
    class func copyFile(fileName : NSString) {
        let dbPath : String = getPath(fileName as String)
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(dbPath) {
            
            let documentsURL = NSBundle.mainBundle().resourceURL
            let fromPath = documentsURL!.URLByAppendingPathComponent(fileName as String)
            
            var error:NSError?
            do {
                try fileManager.copyItemAtPath(fromPath.path!, toPath: dbPath)
            } catch let error1 as NSError {
                error = error1
            }
            
            if error != nil {
                print("Error occured :\(error!.localizedDescription)")
            } else {
                print("Your database copy successfully")
            }
        }
        
    }
    
    class func formattedCurrentDate() -> String {
        let currDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-DD HH:mm:ss"
        let convertDate = dateFormatter.stringFromDate(currDate)
        return convertDate
    }
    
    class func getCurrentDate() -> String {
        let currDate = NSDate()
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyyMMDDHHmmss"
        let convertDate = dateFormatter.stringFromDate(currDate)
        return convertDate
    }
    
    class func stringFromTimeInterval(interval: NSTimeInterval) -> String{
        let time = Int(interval)
        let milli = (time % 60)
        let sec = (time / 60) % 60
        let min = time / 3600
        return  NSString(format: "%02d:%02d:%02d", min, sec, milli) as String
    }

    
    class func showAlertOK(title:String, msg:String, view:UIViewController){
        // create the alert
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.Alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        
        
        
        view.presentViewController(alert, animated: true, completion: nil)
    }
}