//
//  ViewController.swift
//  SDDatabase
//
//  Created by Sagar Dagdu on 01/26/2019.
//  Copyright (c) 2019 Sagar Dagdu. All rights reserved.
//

import UIKit
import SDDatabase

struct AppConstants {
    static let databaseName = "TestDB.sqlite"
}

/**
 This struct represents a table in the database.
 */
struct StudentTable {
    static let tableName = "student"
    static let schema = " ("
        + "roll_number" + " INT PRIMARY KEY, "
        + "name" + " text"
        + ") "
    struct Columns {
        static let rollNumber = "roll_number"
        static let name = "name"
    }
}

class ViewController: UIViewController {
    
    private var database: SDDatabase!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initializeDatabase()
        self.testDatabase()
    }
    
    private func initializeDatabase() {
        guard let database = SDDatabase(withPath: self.databasePath()) else {
            fatalError("Could not initialize database!")
        }
        
        /* Set this to false if you do not want database to log to the console */
        database.loggingEnabled = true
        self.database = database
    }
    
    private func testDatabase() {
        /* Database creation */
        let _ = self.database.create(table: StudentTable.tableName, withSchema: StudentTable.schema)
        
        /* Insert into the table */
        var studentValues = [String:Any]()
        studentValues[StudentTable.Columns.rollNumber] = 1
        studentValues[StudentTable.Columns.name] = "Sagar"
        let _ = self.database.insert(intoTable: StudentTable.tableName, values: studentValues)
        
        /* Print all students whose name is "Sagar" */
        guard let records = self.database.select(fromTable: StudentTable.tableName, columns: [StudentTable.Columns.rollNumber, StudentTable.Columns.name], whereClause: "\(StudentTable.Columns.name) = ?", whereValues: ["Sagar"]) else {
            debugPrint("Could not fetch records")
            return
        }
        
        for record in records {
            let rollNumber = record[StudentTable.Columns.rollNumber] as! Int
            let name = record[StudentTable.Columns.name] as! String
            debugPrint("Roll number : \(rollNumber), name is \(name)")
        }
        
        /* Update the name of students to "Other" where name is "Sagar" using the update method */
        let _ = self.database.update(table: StudentTable.tableName, set: [StudentTable.Columns.name : "Other"], whereClause: "\(StudentTable.Columns.name) = ?", whereValues: ["Sagar"])
        
        /* Update the name of students to "Sagar" where roll number is "Sagar" using the RAW update query */
        let _ = self.database.executeUpdate("UPDATE \(StudentTable.tableName) set \(StudentTable.Columns.name) = ? where \(StudentTable.Columns.rollNumber) = ?", withValues: ["Sagar", 2])
        
        /* Delete student whose roll number is 1 */
        let _ = self.database.delete(fromtable: StudentTable.tableName, where: "\(StudentTable.Columns.rollNumber) = ?", whereValues: [1])
        
        /* Drop the table student*/
        let _ = self.database.drop(table: StudentTable.tableName)
    }
    
    private func databasePath() -> String {
        let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let documentDirDatabasePath = documentDirectoryPath.appending("/\(AppConstants.databaseName)")
        debugPrint(documentDirDatabasePath)
        return documentDirDatabasePath
    }
}

