//
//  SDDatabase.swift
//  SDDatabase
//
//  Created by Sagar Dagdu on 01/26/2019.
//  Copyright (c) 2019 Sagar Dagdu. All rights reserved.
//

import FMDB

public class SDDatabase: NSObject {
    
    //MARK:- Properties
    
    /** The database path. If the file specified doesn't exist, a new file with the given name will be created. */
    private var databasePath:String
    
    /** The FMDatabaseQueue that will be used for all database queries. */
    private var dbQueue: FMDatabaseQueue!
    
    /** The key to be used for the database. If no key is specified, the database file will be unencrypted. */
    private var dbPassKey: String?
    
    /** This property is used to determine whether this class should log errors and other information in debug build. In release build, logs are not enabled. */
    public var loggingEnabled: Bool = true
    
    //MARK:- Initialization
    
    /**
     Initialize the database with db file at the specified path.
     - Parameters:
        - dbPath: The database path. If the file specified doesn't exist, a new file with the given name will be created.
        - key: The key, if the database is encrypted
     - Returns
        `nil` if the specified key isn't able to decrypt the db file successfully
     */
    public init?(withPath dbPath: String, key:String? = nil) {
        self.databasePath = dbPath
        self.dbPassKey = key
        self.dbQueue = FMDatabaseQueue(path: self.databasePath)
        super.init()
        if self.dbPassKey != nil && !self.doesKeyOpenDB() {
            return nil
        }
    }
    
    //MARK:- Core Private methods
    
    fileprivate func executeUpdate(onDatabase database:FMDatabase, withStatement statement:String, values: [Any]?) -> Bool {
        var success:Bool = false
        do {
            database.logsErrors = self.loggingEnabled
            if let key = self.dbPassKey {
                database.setKey(key)
            }
            try database.executeUpdate(statement, values:values)
            success = true
        }
        catch {
            self.log("Error in \(#function) with query: \(statement), error : \(error)")
        }
        return success
    }
    
    fileprivate func executeQuery(query:String, onDatabase database:FMDatabase, withValues values:[Any]?) -> FMResultSet? {
        var resultSet: FMResultSet? = nil
        do  {
            database.logsErrors = self.loggingEnabled
            if let key = self.dbPassKey {
                database.setKey(key)
            }
            resultSet = try database.executeQuery(query, values: values)
        }
        catch {
            self.log("Error in \(#function) with query: \(query), error : \(error)")
        }
        return resultSet
    }
    
    fileprivate func rows(fromResultSet resultSet:FMResultSet?) -> [[AnyHashable : Any?]]? {
        guard let resultSet = resultSet else {
            return nil
        }
        var rows = [[AnyHashable: Any?]]()
        while resultSet.next() {
            let row = resultSet.resultDictionary
            if let row = row {
                rows.append(row)
            }
        }
        return rows
    }
    
    fileprivate func doesKeyOpenDB() -> Bool {
        var success = false
        self.dbQueue.inDatabase { (database) in
            let key = self.dbPassKey!
            database.setKey(key)
            do {
                let _ = try database.executeQuery("SELECT count(*) FROM sqlite_master;", values: nil)
                success = true
            } catch {
                log("Couldn't open DB using the specified key, error is \(error)")
            }
            defer {
                database.close()
            }
            
        }
        return success
    }
    
    fileprivate func log(_ string:String) {
        if self.loggingEnabled {
            debugPrint(string)
        }
    }
}

//MARK: Raw Queries

public extension SDDatabase {
    
    /**
     Execute a raw query
     
     Example: To select all students whose first name is Sagar,
     ````
     let query = "SELECT * from student where name = ?"
     let values = ["Sagar"]
     let rows = db.executeQuery(query, values)
     for row in rows {
        if let name = row["name"] {
            print("Name : \(name)")
        }
     }
     ````
     - Parameters:
        - query: The query to execute
        - whereValues: The values to be used in the query for the specified placeholders. This parameter is **OPTIONAL**
     - Returns
        An array of dictionaries. This array represents rows, and each dictionary is row where key is column name and value is the value of that record. The keys to the dictionary are case sensitive of the column names.
     */
    public func executeQuery(_ query: String, withValues whereValues:[Any]? = nil) -> [[AnyHashable : Any?]]? {
        var rows:[[AnyHashable : Any?]]? = nil
        self.dbQueue.inDatabase { (database) in
            let resultSet = self.executeQuery(query: query, onDatabase: database, withValues: whereValues)
            rows = self.rows(fromResultSet: resultSet)
            if let resultSet = resultSet {
                resultSet.close()
            }
        }
        return rows
    }
    
    /**
     Execute a raw update statement on the database
     
     Example: To update name of a student,
     ````
     let success = db.executeUpdate("UPDATE student set name = ? where roll_number = ?", withValues: ["Other", 2])
     ````
     - Parameters:
        - sql: The update query to execute
        - values: The values to be used in the query for the specified placeholders This parameter is **OPTIONAL**
     - Returns
     `true` if the update was successful, `false` otherwise.
     */
    public func executeUpdate(_ sql: String, withValues values:[Any]? = nil) -> Bool {
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: sql, values: values)
        }
        return success
    }
}

//MARK:- DML

public extension SDDatabase {
    
    /**
     Perform SELECT query on the database
     
     Example : To select students whose name is Sagar,
     ````
     let records = db.select(fromTable: "student", columns: ["roll_number", "name"], whereClause: "name = ?", whereValues: ["Sagar"], offset: 0, limit: 1) else {
        return
     }
     
     for record in records {
        let rollNumber = record["roll_number"] as! Int
        let name = record["name"] as! String
        print("Roll number : \(rollNumber), name is \(name)")
     }
     ````
     - Parameters:
        - table: The table from which the records are to be selected
        - columns: List of columns which are to be selected. If not passed, all the columns will be selected by default i.e. `SELECT * ` will be executed
        - whereClause: The where statement
        - whereValues: The values to be replaced in the whereClause placeholders
        - offset: The offset from where the rows are to be selected
        - limit: number of rows to select
     - Returns
     An array of dictionaries. This array represents rows, and each dictionary is row where key is column name and value is the value of that record. The keys to the dictionary are case sensitive of the column names.
     */
    public func select(fromTable table:String, columns:[String]? = nil,
                       whereClause: String? = nil, whereValues:[Any]? = nil,
                       offset:UInt = 0,limit:UInt = 0) -> [[AnyHashable : Any?]]? {
        var projection: String = "*"
        var whereStatement: String = ""
        
        if let columns = columns {
            projection = columns.joined(separator: ",")
        }
        if let whereClause = whereClause {
            whereStatement = whereClause
        }
        
        var query = String(format: "SELECT %@ from %@ WHERE %@", projection, table, whereStatement, offset)
        
        if limit > 0 {
            query = query.appendingFormat(" LIMIT %d", limit)
        }
        
        if offset > 0 {
            query = query.appendingFormat(" OFFSET %d", offset)
        }
        
        return self.executeQuery(query, withValues: whereValues)
    }
    
    /**
     Perform INSERT on a table in the database
     
     Example: To insert a row in the student table:
     ````
     var student = [String:Any]()
     student["roll_number"] = 1
     student["name"] = "Sagar"
     let success = db.insert(intoTable: "student", values: student)
     ````
     
     - Parameters:
        -  tableName: The table into which row is to be inserted
        -  values: The dictionary of row. Here, the key represents the column name and the value represents the value for that column.
     - Returns:
        `true` if the insert was successful, false otherwise
     */
    public func insert(intoTable tableName: String, values:[String:Any]) -> Bool {
        var columnNames = [String]()
        var columnValues = [Any]()
        var columnValuePlaceholders = [String]()
        
        for pair in values {
            columnNames.append(pair.key)
            columnValuePlaceholders.append("?")
            columnValues.append(pair.value)
        }
        let columnsQuery =  columnNames.joined(separator: ",")
        let valuesQuery =  columnValuePlaceholders.joined(separator: ",")
        let sqlQuery = "INSERT into \(tableName) (\(columnsQuery)) VALUES (\(valuesQuery));"
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: sqlQuery, values: columnValues)
        }
        return success
    }
    
    /**
     Perform UPDATE on the database
     
     Example: To update the name of the student whose name is Sagar:
     ````
     let success = db.update(table: "student", set: ["name" : "Other"], whereClause: "name = ?", whereValues: ["Sagar"])
     ````
     - Parameters:
        - tableName: The table which is to be updated
        - values: The dictionary of values which are to be updated. Here, the key represents the column name and the value represents the value for that column.
        - whereClause: The where statement
        - whereValues: The values to be replaced in the whereClause placeholders
     - Returns:
     `true` if the update was successful, `false` otherwise
     */
    public func update(table tableName:String, set values:[String:Any], whereClause:String? = nil, whereValues:[Any]? = nil) -> Bool {
        var columnNames = [String]()
        var columnValues = [Any]()
        
        for pair in values {
            columnNames.append("\(pair.key) = ?")
            columnValues.append(pair.value)
        }
        let updateString = columnNames.joined(separator: ",")
        var query: String
        if let whereClause = whereClause, let whereValues = whereValues {
            query = "UPDATE \(tableName) set \(updateString) WHERE \(whereClause)"
            columnValues.append(contentsOf: whereValues)
        } else {
            query = "UPDATE \(tableName) set \(updateString)"
        }
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: query, values: columnValues)
        }
        return success
    }
    
    /**
     To perform a DELETE statement on a table in database
     
     Example: To delete a record from student table whose roll_number is 1:
     ````
     let success = db.delete(fromtable: "student", where: "roll_number = ?", whereValues: [1])
     ````
     - Parameters:
        - tableName: The table from which rows are to be deleted
        - whereClause: The where statement
        - whereValues: The values to be replaced in the whereClause placeholders
    - Returns:
      `true` if the delete was successful, `false` otherwise
     */
    public func delete(fromtable tableName: String, where whereClause:String, whereValues:[Any]) -> Bool {
        let deleteStatement = "DELETE FROM \(tableName) WHERE \(whereClause) ;"
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: deleteStatement, values: whereValues)
        }
        return success
    }
    
}

//MARK:- DDL

public extension SDDatabase {
    
    /**
    CREATE a table in the database.
     
     Example: To create a table named student which has two columns,
     ````
     let studentSchema = " ("
     + "roll_number" + " INT PRIMARY KEY, "
     + "name" + " text"
     + ") "
     let success = db.create(table: "student", withSchema: studentSchema)
     ````
     - Parameters:
        - tableName: Nameof the table to be created. The table will be created if it doesn't exist
        - schema: The schema of the table to be created
    - Returns:
     `true` if the table creation was successful, `false` otherwise
     */
    public func create(table tableName: String, withSchema schema:String) -> Bool {
        let createStatement = String(format: "CREATE TABLE if not exists %@ %@;", tableName, schema)
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: createStatement, values: nil)
        }
        return success
    }
    
    /**
     Drop a table from the database.
     - Parameters:
        - tableName: The name of the table to be dropped
     - Returns `true` if the table was successfully dropped, `false` otherwise
     */
    public func drop(table tableName: String) -> Bool {
        let dropStatement = String.init(format: "DROP TABLE if exists %@ ;", tableName)
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: dropStatement, values: [tableName])
        }
        return success
    }
    /**
     Truncate a table.
     
     It is debatable whether this method should be in DDL extension as it uses DELETE internally, but as SQLite doesn't support `truncate`, it is kept here.
     - Parameters:
        - tableName: The name of the table to be truncated
     - Returns `true` if truncation was successful, `false` otherwise
     */
    public func truncate(table tableName:String) -> Bool {
        let truncateStatement = "DELETE FROM \(tableName);"
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = self.executeUpdate(onDatabase: database, withStatement: truncateStatement, values: nil)
        }
        return success
    }
    
}

//MARK:- Transaction Support

public extension SDDatabase {
    /**
     Begin a transaction on the database. After this call, all the statements until `commitTransaction()` call are executed in a transaction
     
    - Returns
     `true` if successfully began a transaction, `false` otherwise
     - See
     `commitTransaction()`
     */
    public func beginTransaction() -> Bool {
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = database.beginTransaction()
        }
        return success
    }
    
    /**
     Commit a transaction that was initiated with `beginTransaction()`
     - Returns
     `true` if successfully committed a transaction, `false` otherwise
     - See
     `beginTransaction()`
     */
    public func commitTransaction() -> Bool {
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = database.commit()
        }
        return success
    }
    
    /**
     Rollback a transaction that was initiated with `beginTransaction()`
     - Returns
     `true` if successfully rolled back a transaction, `false` otherwise
     - See
     `beginTransaction()`
     */
    public func rollback() -> Bool {
        var success: Bool = false
        self.dbQueue.inDatabase { (database) in
            success = database.rollback()
        }
        return success
    }
    
    /**
     Check whether the database is in a transaction
     - Returns
     `true` if the database is in a transaction, `false` otherwise
     - See
     `beginTransaction()`
     */
    public func isInTransaction() -> Bool {
        var isInTransaction: Bool = false
        self.dbQueue.inDatabase { (database) in
            isInTransaction = database.isInTransaction
        }
        return isInTransaction
    }
    
}
