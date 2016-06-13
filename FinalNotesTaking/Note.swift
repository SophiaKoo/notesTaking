//
//  Note.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/17/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import UIKit

class Note: NSObject {
    var id:Int
    var noteText: String
    var dateCreated: String
    var dateModified: String
    var latitude : Double
    var longitude : Double
    var image : String
    var audio : String
    
    override init() {
        id = -1
        noteText = ""
        dateCreated = ""
        dateModified = ""
        latitude = 0.0
        longitude = 0.0
        image = ""
        audio = ""
    }
}
