import struct Foundation.URL

public typealias DocDBDictionary = [String: Any]

public struct DocDBQueryOptions {
	
	public let limit: UInt32
	public let columns: [String]
	
	public init(limit: UInt32 = 100, columns: [String] = []) {
		self.limit = limit
		self.columns = columns
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
	case documentNotFoundForUpdate
}

public struct DocDBOptions {
	
	public let maxFolderDepth: UInt8
	public let serializer: DocDBSerializer
	
	public init(maxFolderDepth: UInt8, serializer: DocDBSerializer) {
		self.maxFolderDepth = maxFolderDepth
		self.serializer = serializer
	}
}
