//
//  DocDB.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

import class Foundation.NSNull
import class LowDocDB.LowDocDB
import struct Foundation.URL
import struct LowDocDB.DocPath
#if canImport(Combine)
import struct Combine.AnyPublisher
#endif

/// Document database
public class DocDB {
	
	private let lowDocDB: LowDocDB
	private let options: DocDBOptions
	
	/// Initializes a `DocDB` with a `LowDocDB`, responsible for accessing the internal methods, and some useful options.
	/// - Parameters:
	///   - rootFolder: The physical hard drive folder path that will be the root of the database. If this is not a folder it will throw a `fatalError` will be thrown.
	///   - options: Database options like the serializer
	public init(rootFolder: URL, options: DocDBOptions = .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer())) {
		self.lowDocDB = LowDocDB(rootFolder: rootFolder, options: .init(maxDepth: options.maxFolderDepth))
		self.options = options
	}
	
	// CREATE
	
	/// Adds a document to the database.
	///
	/// Overrides any existing file.
	/// - Parameters:
	///   - docPath: Relative path of the new document
	///   - data: Document data
	/// - Throws: `LowDocDBError.maxDepthLimitReached` if max depth is reached, other error if fails to create the intermediate folders
	public func addDocument(at docPath: DocPath, dictionary: DocDBDictionary) throws {
		let data = try options.serializer.encode(dictionary: dictionary)
		try lowDocDB.addDocument(at: docPath, data: data)
	}
	
	// UPDATE
	
	/// Updates an existing document with the key-value pairs on the `updateDictionary`.
	///
	/// The only fields that will be updated are the ones found on `updateDictionary`, the rest of the key-value pairs will remain the same.
	/// - Parameters:
	///   - docPath: Document path to be updated
	///   - updateDictionary: A dictionary with only the key-values you want to update.
	/// - Throws: `DocDBError.documentNotFoundForUpdate` if the document was not found, or other errors for adding the document.
	/// - Returns: The updated document
	public func updateDocument(at docPath: DocPath, updateDictionary: DocDBDictionary) throws -> DocDBDictionary {
		guard let document = try self.document(at: docPath) else {
			throw DocDBError.documentNotFoundForUpdate
		}
		var updatedDocument = document
		for (key, value) in updateDictionary {
			updatedDocument[key] = value
		}
		try self.addDocument(at: docPath, dictionary: updatedDocument)
		return updatedDocument
	}
	
	// READ
	
	/// Retrieves a document and returns its data representation
	/// - Parameter docPath: Relative path of the document
	/// - Returns: A `Data` object if document was found and is valid, `nil` otherwise (file doesn't exist, is a folder, etc)
	public func document(at docPath: DocPath) throws -> DocDBDictionary? {
		guard let data = lowDocDB.document(at: docPath) else { return nil }
		return try options.serializer.decode(data: data)
	}
	
	/// If a document (either folder or file) exists
	/// - Parameter docPath: Relative path of the document
	/// - Returns: `true` if file exists, `false` otherwise
	public func documentExist(at docPath: DocPath) -> Bool {
		return lowDocDB.documentExist(at: docPath)
	}
	
	/// Iterator that can enumerate all files within a given folder.
	/// - Parameters:
	///   - folderPath: A relative folder path.
	///   - includeFolders: Whether include folders or not while enumerating files.
	/// - Throws:
	/// `LowDocDBError.folderDoesNotExist` if folder does't exit.
	/// `LowDocDBError.pathMustBeADirectory` if path is not a valid directory.
	/// - Returns: An iterator which values are of `DocPath` type
	public func enumerator(at folderPath: DocPath, includeFolders: Bool) throws -> LowDocDB.Iterator {
		return try lowDocDB.enumerator(at: folderPath, includeFolders: includeFolders)
	}
	
	/// All document paths, including folder or not, from the given `folderPath`.
	/// - Parameters:
	///   - folderPath: Relative folder path.
	///   - includingFolders: Wether to include folders or not when returning the paths.
	/// - Throws: `LowDocDBError.pathMustBeADirectory` if path is not a directory, other errors might be thrown due to invalid paths
	/// - Returns: Document paths of files within the given folder
	public func documentPaths(at folderPath: DocPath, includingFolders: Bool) throws -> [DocPath] {
		return try lowDocDB.documentPaths(at: folderPath, includingFolders: includingFolders)
	}
	
	/// If a document exists and is a folder.
	/// - Parameter docPath: A relative document path.
	/// - Returns: true if the document exists and is a folder, false otherwise.
	public func documentIsFolder(_ docPath: DocPath) -> Bool {
		return lowDocDB.documentIsFolder(docPath)
	}
	
	/// An array containing decoded dictionaries from files of the given folder.
	///
	///  It  skips folders.
	/// - Parameter folderPath: A relative folder path to extract document data from its files.
	/// - Throws: An error if folder path is not a directory.
	/// - Returns: An array containing all files in `folderPath` as decoded `DocDBDictionary` objects.
	public func documents(at folderPath: DocPath) throws -> [DocDBDictionary] {
		let dataDocuments = try lowDocDB.documents(at: folderPath)
		return try dataDocuments.map {
			try self.options.serializer.decode(data: $0)
		}
	}
	
	/// Seaches for documents of the database given a location, a query and some options.
	/// This method returns an iterator, so you can call its `next` method to get the next value of the query, instead of returning all the documents at once.
	/// - Parameters:
	///   - folderPath: Location of the queried items
	///   - query: The filter query for the documents
	///   - options: Useful options for the query
	/// - Throws: `DocDBError.documentPathMustBeADirectory` if `folderPath` is not a directory.
	/// - Returns: A query iterator
	public func queryDocumentsIterator(
		at folderPath: DocPath,
		query: [DocDBQueryValue],
		options: DocDBQueryOptions = .init()
	) throws -> QueryIterator {
		return try QueryIterator(folderPath: folderPath, query: query, options: options, docDB: self)
	}
	
	/// Seaches for documents of the database given a location, a query and some options.
	/// This method returns a `AnyPublisher`, so you can call its `sink` method to get the next values of the query.
	/// - Parameters:
	///   - folderPath: Location of the queried items
	///   - query: The filter query for the documents
	///   - options: Useful options for the query
	/// - Throws: `DocDBError.documentPathMustBeADirectory` if `folderPath` is not a directory.
	/// - Returns: A query iterator
	@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
	public func queryDocumentsPublisher(
		at folderPath: DocPath,
		query: [DocDBQueryValue],
		options: DocDBQueryOptions = .init()
	) throws -> AnyPublisher<DocDBDictionary, Error> {
		return QueryPublisher(queryIterator: try self.queryDocumentsIterator(at: folderPath, query: query, options: options)).eraseToAnyPublisher()
	}
	
	/// Seaches for documents of the database given a location, a query and some options.
	/// This method returns all results at once, consider using `queryDocumentsIterator` instead for returning just the next query result.
	/// - Parameters:
	///   - folderPath: Location of the queried items
	///   - query: The filter query for the documents
	///   - options: Useful options for the query
	/// - Throws: `DocDBError.documentPathMustBeADirectory` if `folderPath` is not a directory.
	/// - Returns: A query iterator
	public func queryDocuments(
		at folderPath: DocPath,
		query: [DocDBQueryValue],
		options: DocDBQueryOptions = .init()
	) throws -> [DocDBDictionary] {
		
		guard self.documentIsFolder(folderPath) else {
			throw DocDBError.documentPathMustBeADirectory
		}
		
		let documentsIterator = try self.enumerator(at: folderPath, includeFolders: false)
		
		var output: [DocDBDictionary] = []
		
		for documentPath in documentsIterator where output.count < options.limit {
			
			guard let document = try? self.document(at: documentPath) else { continue }
			
			var shouldAdd = true
			queryLoop: for queryOption in query {
				switch queryOption {
				case .doesNotExist(key: let key):
					if document.keys.contains(key) {
						shouldAdd = false
					}
				case .exists(key: let key):
					if !document.keys.contains(key) {
						shouldAdd = false
					}
				case .isNull(key: let key):
					if !(document[key] is NSNull) {
						shouldAdd = false
					}
				case .isNotNull(key: let key):
					if document[key] is NSNull {
						shouldAdd = false
					}
				case .isNullOrDoesNotExist(key: let key):
					if !( !document.keys.contains(key) || document[key] is NSNull){
						shouldAdd = false
					}
				case .isEqualTo(let value, key: let key):
					if !value.equals(document[key]) {
						shouldAdd = false
					}
				case .isNotEqualTo(let value, key: let key):
					if value.equals(document[key]) {
						shouldAdd = false
					}
				case .isLessThan(let value, key: let key):
					if !value.less(document[key]) {
						shouldAdd = false
					}
				case .isLessThanOrEqualTo(let value, key: let key):
					let docValue = document[key]
					if !( value.less(docValue) || value.equals(docValue) ) {
						shouldAdd = false
					}
				case .isGreaterThan(let value, key: let key):
					let docValue = document[key]
					if value.equals(docValue) || value.less(docValue) {
						shouldAdd = false
					}
				case .isGreaterThanOrEqualTo(let value, key: let key):
					let docValue = document[key]
					if value.less(docValue) {
						shouldAdd = false
					}
				case .isAnyOf(let array, key: let key):
					var wasAnyOf = false
					isAnyOf: for value in array.values {
						if value.equals(document[key]) {
							wasAnyOf = true
							break isAnyOf
						}
					}
					if !wasAnyOf {
						shouldAdd = false
					}
				case .isNoneOf(let array, key: let key):
					isNoneOf: for value in array.values {
						if value.equals(document[key]) {
							shouldAdd = false
							break isNoneOf
						}
					}
				}
				if !shouldAdd {
					break queryLoop
				}
			}
			if shouldAdd {
				if options.columns.isEmpty {
					output.append(document)
				} else {
					output.append(document.filter { options.columns.contains($0.key) })
				}
			}
		}
		
		return output
	}
	
	// DELETE
		
	/// Deletes a document. Doesn't delete folders.
	/// - Parameter docPath: Relative path for of a document file.
	/// - Throws: If trying to delete the root folder or if the path is for a directory.
	public func deleteDocument(at docPath: DocPath) throws {
		try lowDocDB.deleteDocument(at: docPath)
	}
	
	/// Deletes a document (either regular file or directory).
	/// - Parameter docPath: Relative document path for a regular file or directory to delete
	/// - Throws: If trying to delete the root folder, other errors might be thrown by the file manager too.
	public func deleteItem(at docPath: DocPath) throws {
		try lowDocDB.deleteItem(at: docPath)
	}
}
