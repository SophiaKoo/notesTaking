//
//  DetailViewController.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/29/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var detailImage:UIImage?
    var detailImageIdx:Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = detailImage
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnCancel(sender: UIBarButtonItem) {
        dismissView()
    }

    @IBAction func btnTrash(sender: UIBarButtonItem) {
        images.removeAtIndex(detailImageIdx!)
        dismissView()
    }
    
    func dismissView(){
        navigationController?.popViewControllerAnimated(true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
