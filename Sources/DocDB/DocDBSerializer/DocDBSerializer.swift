//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

import struct Foundation.Data

public protocol DocDBEncoder {
	func encode(dictionary: DocDBDictionary) throws -> Data
}
public protocol DocDBDecoder {
	func decode(data: Data) throws -> DocDBDictionary
}

public protocol DocDBSerializer: DocDBEncoder & DocDBDecoder {}
