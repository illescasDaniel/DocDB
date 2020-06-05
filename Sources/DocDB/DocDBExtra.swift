public typealias DocDBDictionary = [String: Any]

public struct DocDBQueryOptions {
	
	public let limit: UInt32
	
	public init(limit: UInt32) {
		self.limit = limit
	}
	
	// TODO?
//	let orderBy: ((_ lhs: DocDBDictionary, _ rhs: DocDBDictionary) -> Bool)?
//
//	init(
//		limit: UInt32,
//		orderBy: ((_ lhs: DocDBDictionary, _ rhs: DocDBDictionary) -> Bool)? = nil
//	) {
//		self.limit = limit
//		self.orderBy = orderBy
//	}
}


public enum DocDBError: Error {
	case documentPathMustBeADirectory
	case enumeratorError
}

public struct DocDBOptions {
	public let serializer: DocDBSerializer
	public init(serializer: DocDBSerializer) {
		self.serializer = serializer
	}
}
