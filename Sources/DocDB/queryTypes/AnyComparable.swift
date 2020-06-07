//
//  AnyComparable.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

public struct AnyComparable {
	public let value: Any
	public let equals: (Any?) -> Bool
	public let less: (Any?) -> Bool
	
	public init<T: Comparable>(_ value: T) {
		self.value = value
		self.equals = { ($0 as? T) == value }
		self.less = {
			guard let any = $0, let casted = any as? T else { return false }
			return casted < value
		}
	}
}
extension AnyComparable: Equatable, Comparable {
	public static func ==(lhs: AnyComparable, rhs: AnyComparable) -> Bool {
		return lhs.equals(rhs.value)
	}
	public static func < (lhs: AnyComparable, rhs: AnyComparable) -> Bool {
		return lhs.less(rhs.value)
	}
}
