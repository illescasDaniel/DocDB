//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

import struct Foundation.Data
import class Foundation.JSONSerialization

public class JSONSerializationDocDBSerializer: DocDBSerializer {
	
	public init() {}
	
	public func encode(dictionary: DocDBDictionary) throws -> Data {
		try JSONSerialization.data(withJSONObject: dictionary, options: [])
	}
	
	public enum DecodingError: Error {
		case invalidCastingToDictionary
	}
	public func decode(data: Data) throws -> DocDBDictionary {
		let json = try JSONSerialization.jsonObject(with: data, options: [])
		guard let dictionary = json as? DocDBDictionary else {
			throw DecodingError.invalidCastingToDictionary
		}
		return dictionary
	}
}
