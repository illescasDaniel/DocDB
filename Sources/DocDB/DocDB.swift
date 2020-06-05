//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

import class Foundation.NSNull
@_exported import class LowDocDB.LowDocDB
@_exported import struct LowDocDB.DocPath

public class DocDB {
	
	private let lowDocDB: LowDocDB
	private let options: DocDBOptions
	
	public init(lowDocDB: LowDocDB, options: DocDBOptions = .init(serializer: JSONSerializationDocDBSerializer())) {
		self.lowDocDB = lowDocDB
		self.options = options
	}
	
	// CREATE
	
	public func addDocument(at docPath: DocPath, dictionary: DocDBDictionary) throws {
		let data = try options.serializer.encode(dictionary: dictionary)
		try lowDocDB.addDocument(at: docPath, data: data)
    }
	
	// UPDATE
    
	// ?
	
	// READ
    
	public func document(at docPath: DocPath) throws -> DocDBDictionary? {
		guard let data = lowDocDB.document(at: docPath) else { return nil }
		return try options.serializer.decode(data: data)
    }
    
    public func documentExist(at docPath: DocPath) -> Bool {
		return lowDocDB.documentExist(at: docPath)
    }
	
	public func enumerator(at folderPath: DocPath) throws -> LowDocDB.Iterator {
		return try lowDocDB.enumerator(at: folderPath)
	}
    
    public func documentPaths(at folderPath: DocPath) throws -> [DocPath] {
		return try lowDocDB.documentPaths(at: folderPath)
    }
    
    public func documentIsFolder(_ docPath: DocPath) -> Bool {
		return lowDocDB.documentIsFolder(docPath)
    }
    
    public func documents(at folderPath: DocPath) throws -> [DocDBDictionary] {
		let dataDocuments = try lowDocDB.documents(at: folderPath)
		return try dataDocuments.compactMap {
			try self.options.serializer.decode(data: $0)
		}
    }
	
	public func queryDocuments(
		at folderPath: DocPath,
		query: [DocDBQueryValue],
		options: DocDBQueryOptions = .init(limit: 100)
	) throws -> [DocDBDictionary] {
		
		guard self.documentIsFolder(folderPath) else {
			throw DocDBError.documentPathMustBeADirectory
		}
		
		let documentsIterator = try self.enumerator(at: folderPath)
		
		var output: [DocDBDictionary] = []
		
		for documentPath in documentsIterator where output.count < options.limit {
			
			guard let document = try self.document(at: documentPath) else { continue }
			
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
				output.append(document)
			}
		}
		
		return output
	}
    
	// DELETE
	
    public func deleteDocument(at docPath: DocPath) throws {
		try lowDocDB.deleteDocument(at: docPath)
    }
}
