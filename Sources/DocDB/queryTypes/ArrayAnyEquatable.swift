//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

public class ArrayAnyEquatable {
	
	public let values: [AnyEquatable]
	
	public init<T: Equatable>(_ values: [T]) {
		self.values = values.map { AnyEquatable($0) }
	}
}
