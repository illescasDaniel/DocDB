//
//  DocDBQueryValue.swift
//  
//
//  Created by Daniel Illescas Romero on 05/06/2020.
//

public enum DocDBQueryValue {
	
	case doesNotExist(key: String)
	case exists(key: String)
	
	case isNull(key: String)
	case isNotNull(key: String)
	
	case isNullOrDoesNotExist(key: String)
	
	case isEqualTo(_ value: AnyEquatable, key: String)
	case isNotEqualTo(_ value: AnyEquatable, key: String)
	case isLessThan(_ value: AnyComparable, key: String)
	case isLessThanOrEqualTo(_ value: AnyComparable, key: String)
	case isGreaterThan(_ value: AnyComparable, key: String)
	case isGreaterThanOrEqualTo(_ value: AnyComparable, key: String)
	
	case isAnyOf(_ values: ArrayAnyEquatable, key: String)
	case isNoneOf(_ values: ArrayAnyEquatable, key: String)
}
