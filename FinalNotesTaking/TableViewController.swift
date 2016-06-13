//
//  TableViewController.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/17/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import UIKit



class TableViewController: UITableViewController {

    var marrNotes:NSMutableArray = NSMutableArray()
    
    var actInd : UIActivityIndicatorView?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //getNotesList()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        NSLog("viewWillAppear")
        getNotesList()
    }
    
    func addControls() {
        actInd = UIActivityIndicatorView(frame: CGRectMake(0,0,50,50))
        actInd!.center = self.view.center
        actInd!.hidesWhenStopped = true
        actInd!.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
        view.addSubview(actInd!)
    }
    
    func getNotesList() {
        addControls()
        actInd!.startAnimating()
        self.marrNotes = ModelManager.getInstance().getNotesList()
        tableView.reloadData()
        actInd!.stopAnimating()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return marrNotes.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

        // Configure the cell...
        let note:Note = marrNotes.objectAtIndex(indexPath.row) as! Note
        cell.textLabel?.text = note.noteText
        
        if note.audio == "" {
            cell.detailTextLabel?.text = note.dateModified
        }else{
            cell.detailTextLabel?.text = note.dateModified + " \u{1F50A}"
        }
        
        let arrImage = note.image.componentsSeparatedByString(";")
        if arrImage.count > 0 {
            let imagePath = Util.getPath(arrImage[0])
            let image = UIImage(contentsOfFile: imagePath)
            cell.accessoryView = UIImageView(image: image)
            cell.accessoryView!.frame = CGRectMake(0,0,100,cell.frame.size.height - 5)
        }
        
        return cell
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let note:Note = marrNotes.objectAtIndex(indexPath.row) as! Note
        ModelManager.getInstance().deleteNote(note)
        marrNotes.removeObjectAtIndex(indexPath.row)
        tableView.reloadData()
        //if isDelete {
        //    getNotesList()
        //}
        
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "edit" {
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            let viewController:ViewController = segue.destinationViewController as! ViewController
            
            let currentNote = marrNotes.objectAtIndex(indexPath!.row) as! Note
            viewController.curNote = currentNote
        }
    }
    
}
