# SDDatabase
[![Version](https://img.shields.io/cocoapods/v/SDDatabase.svg?style=flat)](https://cocoapods.org/pods/SDDatabase)
[![License](https://img.shields.io/cocoapods/l/SDDatabase.svg?style=flat)](https://cocoapods.org/pods/SDDatabase)
[![Platform](https://img.shields.io/cocoapods/p/SDDatabase.svg?style=flat)](https://cocoapods.org/pods/SDDatabase)

SDDatabase is a simple yet powerful wrapper over the famous [FMDB](https://github.com/ccgus/fmdb). Provides fast and easy access to sqlite database operations in iOS eliminating all the boilerplate code. Written with ❤️ in Swift.

## Features of  `SDDatabase` : 
- Easy to use, provides direct methods for `create`, `insert`, `update`, `delete`, `select`, and others... No need to use raw queries for the above operations
- No worries about multi threading, as each `SDDatabase` instance has its own `FMDatabaseQueue` and all the wrapper methods are called on this queue. Create one instance in a singleton and use it throughout the application.
- Transaction support.
- Ability to deal with encrypted database files, uses [SQLCipher](https://www.zetetic.net/sqlcipher/)
- No need to deal with complex resultSet objects, `SDDatabase` returns results in and array of dictionaries which can be iterated over. i.e. `[[String : Any]]`
- All the methods are fully documented, including their example usage as well. 😎

Choose `SDDatabase` for your next project which uses SQLite, or migrate over your existing projects—you'll be happy you did!

## Dependencies
SDDatabase is dependent on the **FMDB/SQLCipher** subspec of FMDB. The FMDB/SQLCipher subspec declares SQLCipher as a dependency, allowing FMDB to be compiled with the `-DSQLITE_HAS_CODEC` flag.

## Installation

SDDatabase is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SDDatabase'
```

## Usage 
### Initializing a database
````swift
let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
let databasePath = documentDirectoryPath.appending("/testdb.sqlite")
guard let db = Database(withPath: databasePath) else {
print("DB could not be opened")
return
}
````
If the database file is encrypted, you can use the init with key method
````swift
Database(withPath: self.dbPath(), key: "testKey")
````
You can control whether the library should log any errors or other logs to the console using the property `loggingEnabled`
````swift
/* Set this to false if you do not want database to log to the console */
db.loggingEnabled = true
````

### Creating a table (`create`)
````swift
let studentSchema = " ("
+ "roll_number" + " INT PRIMARY KEY, "
+ "name" + " text"
+ ") "
let creationSuccess = db.create(table: "student", withSchema: studentSchema)
````
#### Inserting a record in the table (`insert`)
````swift
var studentValues = [String:Any]()
studentValues["roll_number"] = 1
studentValues["name"] = "Sagar"
let insertionSuccess = db.insert(intoTable: "student", values: studentValues)
````
#### Selecting records from the table (`select`)
````swift
guard let records = db.select(fromTable: "student", columns: ["roll_number", "name"], whereClause: "name = ?", whereValues: ["Sagar"]) else {
return
}

for record in records {
  let rollNumber = record["roll_number"] as! Int
  let name = record["name"] as! String
  print("Roll number : \(rollNumber), name is \(name)")
}
````

You can also pass offset and limit to the select method, Refer the documentation for more detailed usage

### Updating a record (`update`)
````swift
let updateSuccess = db.update(table: "student", set: ["name" : "Other"], whereClause: "name = ?", whereValues: ["Sagar"])
````
### Deleting a record (`delete`)
````swift
let deletionSuccess = db.delete(fromtable: "student", where: "roll_number = ?", whereValues: [1])
````

### Dropping a table (`drop`)
````swift
let dropSuccess = db.drop(table: "student")
````

### Raw queries
The class provides `executeQuery()` and `executeUpdate()` methods for executing raw SQL statements. Refer to the documentation for detailed usage.

### Transaction management
The class provides `beginTransaction()`, `commitTransaction`, `rollback()` and `isInTransaction()` for handling transaction management. Refer to the documentation for detailed usage.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first. The example project includes the usage of all the methods provided by the library.

## Author

Sagar Dagdu, shags032@gmail.com

## License

SDDatabase is available under the MIT license. See the LICENSE file for more info.

## Contributions

All contributions are welcome. Please fork the project to add functionalities and submit a pull request to merge them in next releases.
