# DocDB

Document-oriented database built upon [LowDocDB](https://github.com/illescasDaniel/LowDocDB).

## Examples
```swift
let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))

let devicesPath = try DocPath("/devices")

let myDevicePath = try devicesPath.appending("device1.data")

// add
try docDB.addDocument(at: myDevicePath, dictionary: [
    "os": "iOS",
    "version": "13.1",
    "something": 1,
    "test1": 12.1,
    "test2": "something",
    "testArray": [1,2,3,10,5,5,6,7,8],
    "testArray2": ["1","2","3","4","5","5","6","7","8"]
])

// retrieve
if let deviceDoc = try docDB.document(at: myDevicePath) {
    print(deviceDoc["os"]) // "iOS"
}

// query
let docsGreaterThan: [DocDBDictionary] = try docDB.queryDocuments(
    at: devicesPath,
    query: [
    	.isGreaterThan(.init(1), key: "something")
    ],
    options: .init(limit: .max, columns: ["something", "test2"])
)

// delete
try docDB.deleteDocument(at: myDevicePath)
```

## Interface
```swift
public class DocDB {

    public init(rootFolder: URL, options: DocDBOptions = .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))

    /// Adds a document to the database.
    public func addDocument(at docPath: DocPath, dictionary: DocDBDictionary) throws

    /// Updates an existing document with the key-value pairs on the `updateDictionary`.
    public func updateDocument(at docPath: DocPath, updateDictionary: DocDBDictionary) throws -> DocDBDictionary

    /// Retrieves a document and returns its data representation
    public func document(at docPath: DocPath) throws -> DocDBDictionary?

    /// If a document (either folder or file) exists
    public func documentExist(at docPath: DocPath) -> Bool

    /// Iterator that can enumerate all files within a given folder.
    public func enumerator(at folderPath: DocPath, includeFolders: Bool) throws -> LowDocDB.Iterator

    /// All document paths, including folder or not, from the given `folderPath`
    public func documentPaths(at folderPath: DocPath, includingFolders: Bool) throws -> [DocPath]

    /// If a document exists and is a folder.
    public func documentIsFolder(_ docPath: DocPath) -> Bool

    /// An array containing decoded dictionaries from files of the given folder.
    public func documents(at folderPath: DocPath) throws -> [DocDBDictionary]

    /// Seaches for documents of the database given a location, a query and some options.
    public func queryDocumentsIterator(at folderPath: DocPath, query: [DocDBQueryValue], options: DocDBQueryOptions = .init()) throws -> QueryIterator

    public func queryDocumentsPublisher(at folderPath: DocPath, query: [DocDBQueryValue], options: DocDBQueryOptions = .init()) throws -> AnyPublisher<DocDBDictionary, Error>

    public func queryDocuments(at folderPath: DocPath, query: [DocDBQueryValue], options: DocDBQueryOptions = .init()) throws -> [DocDBDictionary]

    /// Deletes a document. Doesn't delete folders.
    public func deleteDocument(at docPath: DocPath) throws

    /// Deletes a document (either regular file or directory).
    public func deleteItem(at docPath: DocPath) throws
}
```
