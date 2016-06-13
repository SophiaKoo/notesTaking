//
//  ModelManager.swift
//  FinalNotesTaking
//
//  Created by hyunju koo on 2/17/16.
//  Copyright © 2016 LambtonCollege. All rights reserved.
//

import Foundation

let DBNAME:String = "notes.db"

class ModelManager {
    private var database:FMDatabase?
    private static var sharedInstance:ModelManager?
    private init(){
        database = FMDatabase(path: Util.getPath(DBNAME))
    }
    class func getInstance() -> ModelManager {
        if sharedInstance == nil {
            sharedInstance = ModelManager()
        }
        return sharedInstance!
    }
    
    func addNote(note:Note) -> Bool {
        self.database!.open()
        
        let result = self.database!.executeUpdate("INSERT INTO note (note_text, date_created, date_modified, latitude, longitude, image, audio) VALUES (?, ?, ?, ?, ?, ?, ?)", withArgumentsInArray: [note.noteText, note.dateCreated, note.dateModified, note.latitude, note.longitude, note.image, note.audio])
        self.database!.close()
        return result
    }
    
    func getNotesList() -> NSMutableArray {
        self.database!.open()
        
        let resultSet:FMResultSet! = self.database!.executeQuery("SELECT * FROM note ORDER BY date_modified DESC", withArgumentsInArray: nil)
        let marrNotes:NSMutableArray = NSMutableArray()
        
        if resultSet != nil {
            while resultSet.next() {
                let note : Note = Note()
                note.id = resultSet.longForColumn("id")
                note.noteText = resultSet.stringForColumn("note_text")
                note.dateCreated = resultSet.stringForColumn("date_created")
                note.dateModified = resultSet.stringForColumn("date_modified")
                note.latitude = resultSet.doubleForColumn("latitude")
                note.longitude = resultSet.doubleForColumn("longitude")
                note.image = resultSet.stringForColumn("image")
                note.audio = resultSet.stringForColumn("audio")
                
                marrNotes.addObject(note)
            }
        }
        
        self.database!.close()
        return marrNotes
    }
    
    func updateNote(note:Note) -> Bool {
        self.database!.open()
        let result = self.database!.executeUpdate("UPDATE note SET note_text=?, date_modified=?, image=?, audio=? WHERE id=?", withArgumentsInArray: [note.noteText, note.dateModified, note.image, note.audio, note.id])
        self.database!.close()
        return result
    }
    
    func deleteNote(note:Note) -> Bool {
        self.database!.open()
        let result = self.database!.executeUpdate("DELETE FROM note WHERE id=?", withArgumentsInArray: [note.id])
        self.database!.close()
        return result
    }
}