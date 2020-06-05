//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

import struct Foundation.Data
import class Foundation.NSKeyedArchiver
import class Foundation.NSKeyedUnarchiver

public class NSKeyedArchiverDocDBSerializer: DocDBSerializer {
	
	public init() {}
	
	public func encode(dictionary: DocDBDictionary) throws -> Data {
		try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: true)
	}
	
	public enum DecodingError: Error {
		case invalidCastingToDictionary
	}
	public func decode(data: Data) throws -> DocDBDictionary {
		let object = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
		guard let dictionary = object as? DocDBDictionary else {
			throw DecodingError.invalidCastingToDictionary
		}
		return dictionary
	}
}
