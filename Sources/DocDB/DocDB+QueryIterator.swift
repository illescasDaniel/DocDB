//
//  DocDB+QueryIterator.swift
//  
//
//  Created by Daniel Illescas Romero on 07/06/2020.
//

import class Foundation.NSNull
import struct LowDocDB.DocPath
import class LowDocDB.LowDocDB

public class QueryIterator: Sequence, IteratorProtocol {
	
	public let query: [DocDBQueryValue]
	public let options: DocDBQueryOptions
	
	private let docDB: DocDB
	private let documentsIterator: LowDocDB.Iterator
	private var count = 0
	
	init(
		folderPath: DocPath,
		query: [DocDBQueryValue],
		options: DocDBQueryOptions,
		docDB: DocDB
	) throws {
		
		guard docDB.documentIsFolder(folderPath) else {
			throw DocDBError.documentPathMustBeADirectory
		}
		
		self.documentsIterator = try docDB.enumerator(at: folderPath, includeFolders: false)
		self.query = query
		self.options = options
		self.docDB = docDB
	}
	
	public func next() -> DocDBDictionary? {
		
		guard count < options.limit else { return nil }
		
		for documentPath in documentsIterator {
			
			guard let document = try? docDB.document(at: documentPath) else { continue }
			
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
				count += 1
				if options.columns.isEmpty {
					return document
				} else {
					return document.filter { options.columns.contains($0.key) }
				}
			}
		}
		
		return nil
	}
}
