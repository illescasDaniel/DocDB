//
//  File.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

public struct AnyEquatable {
	public let value: Any
	public let equals: (Any?) -> Bool
	
	public init<T: Equatable>(_ value: T) {
		self.value = value
		self.equals = { ($0 as? T == value) }
	}
}
extension AnyEquatable: Equatable {
	public static func ==(lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
		return lhs.equals(rhs.value)
	}
}
