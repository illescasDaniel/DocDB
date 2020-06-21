#if !os(watchOS)
import XCTest
@testable import DocDB

final class DocDBTests: XCTestCase {
	
	let rootFolder = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent("doc.db")
	let fileManager = FileManager.default
	
	func testSavingDocsAsJSON() {
		try? fileManager.removeItem(at: rootFolder)
		do {
			try fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
			
			let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			try docDB.addDocument(at: try devicesPath.appending("device1.data"), dictionary: [
				"os": "iOS",
				"version": "13.1",
				"something": 1,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			if let deviceDoc = try docDB.document(at: try devicesPath.appending("device1.data")) {
				XCTAssertEqual(deviceDoc["os"] as! String, "iOS")
				XCTAssertEqual(deviceDoc["version"] as! String, "13.1")
				XCTAssertEqual(deviceDoc["something"] as! Int, 1)
				XCTAssertEqual(deviceDoc["test1"] as! Double, 12.1)
				XCTAssertEqual(deviceDoc["test2"] as! String, "something")
				XCTAssertEqual(deviceDoc["testArray"] as! [Int], [1,2,3,10,5,5,6,7,8])
				XCTAssertEqual(deviceDoc["testArray2"] as! [String], ["1","2","3","4","5","5","6","7","8"])
			} else {
				XCTFail("Dictionary can't be nil")
			}
			
			for docPath in try docDB.enumerator(at: devicesPath, includeFolders: true) {
				try docDB.deleteDocument(at: docPath)
			}
			try? fileManager.removeItem(at: rootFolder)
		} catch {
			XCTFail("\(error)")
			try? fileManager.removeItem(at: rootFolder)
		}
	}
	
	func testUpdatingDocument() {
		try? fileManager.removeItem(at: rootFolder)
		do {
			try fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
			
			let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			let devicePath = try devicesPath.appending("device1.json")
			try docDB.addDocument(at: devicePath, dictionary: [
				"os": "iOS",
				"version": "13.1",
				"something": 1,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			let updatedDocument = try docDB.updateDocument(at: devicePath, updateDictionary: [
				"test1": 1234,
				"os": "Android"
			])
			XCTAssertEqual(updatedDocument["os"] as! String, "Android")
			XCTAssertEqual(updatedDocument["version"] as! String, "13.1")
			XCTAssertEqual(updatedDocument["something"] as! Int, 1)
			XCTAssertEqual(updatedDocument["test1"] as! Int, 1234)
			XCTAssertEqual(updatedDocument["test2"] as! String, "something")
			XCTAssertEqual(updatedDocument["testArray"] as! [Int], [1,2,3,10,5,5,6,7,8])
			XCTAssertEqual(updatedDocument["testArray2"] as! [String], ["1","2","3","4","5","5","6","7","8"])
			
			if let retrievedUpdatedDocument = try docDB.document(at: devicePath) {
				XCTAssertEqual(updatedDocument["os"] as! String, retrievedUpdatedDocument["os"] as! String)
				XCTAssertEqual(updatedDocument["version"] as! String, retrievedUpdatedDocument["version"] as! String)
				XCTAssertEqual(updatedDocument["something"] as! Int, retrievedUpdatedDocument["something"] as! Int)
				XCTAssertEqual(updatedDocument["test2"] as! String, retrievedUpdatedDocument["test2"] as! String)
				XCTAssertEqual(updatedDocument["testArray"] as! [Int], retrievedUpdatedDocument["testArray"] as! [Int])
				XCTAssertEqual(updatedDocument["testArray2"] as! [String], retrievedUpdatedDocument["testArray2"] as! [String])
			} else {
				XCTFail("Updated dictionary can't be nil")
			}

			for docPath in try docDB.enumerator(at: devicesPath, includeFolders: true) {
				try docDB.deleteDocument(at: docPath)
			}
			try? fileManager.removeItem(at: rootFolder)
		} catch {
			XCTFail("\(error)")
			try? fileManager.removeItem(at: rootFolder)
		}
	}
	
	func testMeasureSavingDocsAsJSON() {
		try? fileManager.removeItem(at: rootFolder)
		try? fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
		//measure {
			serializeDocs(serializer: JSONSerializationDocDBSerializer(), iterations: 1000)
		//}
		try? fileManager.removeItem(at: rootFolder)
	}
	
	func testMeasureSavingBinaryDocs() {
		try? fileManager.removeItem(at: rootFolder)
		try? fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
		//measure {
			if #available(iOS 11.0, *) {
				serializeDocs(serializer: NSKeyedArchiverDocDBSerializer(), iterations: 1000)
			}
		//}
		try? fileManager.removeItem(at: rootFolder)
	}
	
	func testQuery() {
		try? fileManager.removeItem(at: rootFolder)
		do {
			try fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
			
			let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			let devicePath1 = try devicesPath.appending("device1.json")
			try docDB.addDocument(at: devicePath1, dictionary: [
				"os": "iOS",
				"version": "13.1",
				"something": 1,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			let devicePath2 = try devicesPath.appending("device2.json")
			try docDB.addDocument(at: devicePath2, dictionary: [
				"os": "Android",
				"version": "13.1",
				"something": 3,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			let devicePath3 = try devicesPath.appending("device3.json")
			try docDB.addDocument(at: devicePath3, dictionary: [
				"os": "Android",
				"version": "13.1",
				"something": 4,
				"test1": 14.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			XCTAssertEqual(try docDB.documentPaths(at: devicesPath, includingFolders: false).count, 3)
			
			// limit
			let all3DocsLimitedTo2 = try docDB.queryDocuments(
				at: devicesPath,
				query: [
					.isGreaterThan(.init(0), key: "something")
				],
				options: .init(limit: 2, columns: ["something", "test2"])
			)
			XCTAssertEqual(all3DocsLimitedTo2.count, 2)
			
			for doc in all3DocsLimitedTo2 {
				XCTAssertTrue((doc["something"] as! Int) > 0)
				XCTAssertEqual(doc.keys.count, 2)
			}
			
			// docsGreaterThan
			let docsGreaterThan = try docDB.queryDocuments(
				at: devicesPath,
				query: [
					.isGreaterThan(.init(1), key: "something")
				],
				options: .init(limit: .max, columns: ["something", "test2"])
			)
			XCTAssertEqual(docsGreaterThan.count, 2)
			
			for doc in docsGreaterThan {
				XCTAssertTrue((doc["something"] as! Int) > 1)
				XCTAssertEqual(doc.keys.count, 2)
			}
			
			// docsLessThan
			let docsLessThan = try docDB.queryDocuments(at: devicesPath, query: [
				.isLessThan(.init(13.0), key: "test1")
			], options: .init(limit: .max))
			
			XCTAssertEqual(docsLessThan.count, 2)
			
			for doc in docsLessThan {
				XCTAssertTrue((doc["test1"] as! Double) < 13.0)
			}
			
			// docsEqualTo
			let docsEqualTo = try docDB.queryDocuments(at: devicesPath, query: [
				.isEqualTo(.init("13.1"), key: "version")
			], options: .init(limit: .max))
			
			XCTAssertEqual(docsEqualTo.count, 3)
			
			for doc in docsEqualTo {
				XCTAssertEqual((doc["version"] as! String), "13.1")
			}
			
			// docsNotEqualTo
			let docsNotEqualTo = try docDB.queryDocuments(at: devicesPath, query: [
				.isNotEqualTo(.init([1,23]), key: "testArray")
			], options: .init(limit: .max))
			
			XCTAssertEqual(docsNotEqualTo.count, 3)
			
			for doc in docsNotEqualTo {
				XCTAssertEqual((doc["testArray"] as! [Int]), [1,2,3,10,5,5,6,7,8])
				XCTAssertNotEqual((doc["testArray"] as! [Int]), [1,23])
			}
			
			// docsIsAnyOf
			let docsIsAnyOf = try docDB.queryDocuments(at: devicesPath, query: [
				.isAnyOf(.init([4,1]), key: "something")
			], options: .init(limit: .max))
			
			XCTAssertEqual(docsIsAnyOf.count, 2)
			
			for doc in docsIsAnyOf {
				XCTAssertTrue([4,1].contains((doc["something"] as! Int)))
			}
			
			try? fileManager.removeItem(at: rootFolder)
		} catch {
			XCTFail("\(error)")
			try? fileManager.removeItem(at: rootFolder)
		}
	}
	
	func testQueryIterator() {
		try? fileManager.removeItem(at: rootFolder)
		do {
			try fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
			
			let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			let devicePath1 = try devicesPath.appending("device1.json")
			try docDB.addDocument(at: devicePath1, dictionary: [
				"os": "iOS",
				"version": "13.1",
				"something": 1,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			let devicePath2 = try devicesPath.appending("device2.json")
			try docDB.addDocument(at: devicePath2, dictionary: [
				"os": "Android",
				"version": "13.1",
				"something": 3,
				"test1": 12.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			let devicePath3 = try devicesPath.appending("device3.json")
			try docDB.addDocument(at: devicePath3, dictionary: [
				"os": "Android",
				"version": "13.1",
				"something": 4,
				"test1": 14.1,
				"test2": "something",
				"testArray": [1,2,3,10,5,5,6,7,8],
				"testArray2": ["1","2","3","4","5","5","6","7","8"]
			])
			
			XCTAssertEqual(try docDB.documentPaths(at: devicesPath, includingFolders: false).count, 3)
			
			// limit
			let all3DocsLimitedTo2 = try docDB.queryDocumentsIterator(
				at: devicesPath,
				query: [
					.isGreaterThan(.init(0), key: "something")
				],
				options: .init(limit: 2, columns: ["something", "test2"])
			)
			var all3DocsLimitedTo2Count = 0
			
			for doc in all3DocsLimitedTo2 {
				XCTAssertTrue((doc["something"] as! Int) > 0)
				XCTAssertEqual(doc.keys.count, 2)
				
				all3DocsLimitedTo2Count += 1
			}
			
			XCTAssertEqual(all3DocsLimitedTo2Count, 2)
			
			// docsGreaterThan
			let docsGreaterThan = try docDB.queryDocumentsIterator(
				at: devicesPath,
				query: [
					.isGreaterThan(.init(1), key: "something")
				],
				options: .init(limit: .max, columns: ["something", "test2"])
			)
			
			var docsGreaterThanCount = 0
			
			for doc in docsGreaterThan {
				XCTAssertTrue((doc["something"] as! Int) > 1)
				XCTAssertEqual(doc.keys.count, 2)
				
				docsGreaterThanCount += 1
			}
			
			XCTAssertEqual(docsGreaterThanCount, 2)
			
			// docsLessThan
			let docsLessThan = try docDB.queryDocumentsIterator(at: devicesPath, query: [
				.isLessThan(.init(13.0), key: "test1")
			], options: .init(limit: .max))
			
			var docsLessThanCount = 0
			
			for doc in docsLessThan {
				XCTAssertTrue((doc["test1"] as! Double) < 13.0)
				docsLessThanCount += 1
			}
			
			XCTAssertEqual(docsLessThanCount, 2)
			
			// docsEqualTo
			let docsEqualTo = try docDB.queryDocumentsIterator(at: devicesPath, query: [
				.isEqualTo(.init("13.1"), key: "version")
			], options: .init(limit: .max))
			
			var docsEqualToCount = 0
			
			for doc in docsEqualTo {
				XCTAssertEqual((doc["version"] as! String), "13.1")
				docsEqualToCount += 1
			}
			
			XCTAssertEqual(docsEqualToCount, 3)
			
			// docsNotEqualTo
			let docsNotEqualTo = try docDB.queryDocumentsIterator(at: devicesPath, query: [
				.isNotEqualTo(.init([1,23]), key: "testArray")
			], options: .init(limit: .max))
			
			var docsNotEqualToCount = 0
			
			for doc in docsNotEqualTo {
				XCTAssertEqual((doc["testArray"] as! [Int]), [1,2,3,10,5,5,6,7,8])
				XCTAssertNotEqual((doc["testArray"] as! [Int]), [1,23])
				docsNotEqualToCount += 1
			}
			
			XCTAssertEqual(docsNotEqualToCount, 3)
			
			// docsIsAnyOf
			let docsIsAnyOf = try docDB.queryDocumentsIterator(at: devicesPath, query: [
				.isAnyOf(.init([4,1]), key: "something")
			], options: .init(limit: .max))
			
			var docsIsAnyOfCount = 0
			
			for doc in docsIsAnyOf {
				XCTAssertTrue([4,1].contains((doc["something"] as! Int)))
				docsIsAnyOfCount += 1
			}
			
			XCTAssertEqual(docsIsAnyOfCount, 2)
			
			try? fileManager.removeItem(at: rootFolder)
		} catch {
			XCTFail("\(error)")
			try? fileManager.removeItem(at: rootFolder)
		}
	}
	
	func testQueryPublisher() {
		#if canImport(Combine)
		if #available(OSX 10.15, *) {
			let expectationPublishers = expectation(description: "testQueryPublisher")
			expectationPublishers.expectedFulfillmentCount = 6
			expectationPublishers.assertForOverFulfill = true
			
			try? fileManager.removeItem(at: rootFolder)
			do {
				try fileManager.createDirectory(at: rootFolder, withIntermediateDirectories: false, attributes: nil)
				
				let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
				
				let devicesPath = try DocPath("/devices")
				
				let devicePath1 = try devicesPath.appending("device1.json")
				try docDB.addDocument(at: devicePath1, dictionary: [
					"os": "iOS",
					"version": "13.1",
					"something": 1,
					"test1": 12.1,
					"test2": "something",
					"testArray": [1,2,3,10,5,5,6,7,8],
					"testArray2": ["1","2","3","4","5","5","6","7","8"]
				])
				
				let devicePath2 = try devicesPath.appending("device2.json")
				try docDB.addDocument(at: devicePath2, dictionary: [
					"os": "Android",
					"version": "13.1",
					"something": 3,
					"test1": 12.1,
					"test2": "something",
					"testArray": [1,2,3,10,5,5,6,7,8],
					"testArray2": ["1","2","3","4","5","5","6","7","8"]
				])
				
				let devicePath3 = try devicesPath.appending("device3.json")
				try docDB.addDocument(at: devicePath3, dictionary: [
					"os": "Android",
					"version": "13.1",
					"something": 4,
					"test1": 14.1,
					"test2": "something",
					"testArray": [1,2,3,10,5,5,6,7,8],
					"testArray2": ["1","2","3","4","5","5","6","7","8"]
				])
				
				XCTAssertEqual(try docDB.documentPaths(at: devicesPath, includingFolders: false).count, 3)
				
				// limit
				let all3DocsLimitedTo2 = try docDB.queryDocumentsPublisher(
					at: devicesPath,
					query: [
						.isGreaterThan(.init(0), key: "something")
					],
					options: .init(limit: 2, columns: ["something", "test2"])
				)
				var all3DocsLimitedTo2Count = 0
				
				_ = all3DocsLimitedTo2.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertTrue((doc["something"] as! Int) > 0)
					XCTAssertEqual(doc.keys.count, 2)
					all3DocsLimitedTo2Count += 1
				})
				
				XCTAssertEqual(all3DocsLimitedTo2Count, 2)
				
				// docsGreaterThan
				let docsGreaterThan = try docDB.queryDocumentsPublisher(
					at: devicesPath,
					query: [
						.isGreaterThan(.init(1), key: "something")
					],
					options: .init(limit: .max, columns: ["something", "test2"])
				)
				
				var docsGreaterThanCount = 0
				
				_ = docsGreaterThan.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertTrue((doc["something"] as! Int) > 1)
					XCTAssertEqual(doc.keys.count, 2)
					docsGreaterThanCount += 1
				})
				
				XCTAssertEqual(docsGreaterThanCount, 2)
				
				// docsLessThan
				let docsLessThan = try docDB.queryDocumentsPublisher(at: devicesPath, query: [
					.isLessThan(.init(13.0), key: "test1")
				], options: .init(limit: .max))
				
				var docsLessThanCount = 0
				
				_ = docsLessThan.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertTrue((doc["test1"] as! Double) < 13.0)
					docsLessThanCount += 1
				})
				
				XCTAssertEqual(docsLessThanCount, 2)
				
				// docsEqualTo
				let docsEqualTo = try docDB.queryDocumentsPublisher(at: devicesPath, query: [
					.isEqualTo(.init("13.1"), key: "version")
				], options: .init(limit: .max))
				
				var docsEqualToCount = 0
				
				_ = docsEqualTo.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertEqual((doc["version"] as! String), "13.1")
					docsEqualToCount += 1
				})
				
				XCTAssertEqual(docsEqualToCount, 3)
				
				// docsNotEqualTo
				let docsNotEqualTo = try docDB.queryDocumentsPublisher(at: devicesPath, query: [
					.isNotEqualTo(.init([1,23]), key: "testArray")
				], options: .init(limit: .max))
				
				var docsNotEqualToCount = 0
				
				_ = docsNotEqualTo.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertEqual((doc["testArray"] as! [Int]), [1,2,3,10,5,5,6,7,8])
					XCTAssertNotEqual((doc["testArray"] as! [Int]), [1,23])
					docsNotEqualToCount += 1
				})
				
				XCTAssertEqual(docsNotEqualToCount, 3)
				
				// docsIsAnyOf
				let docsIsAnyOf = try docDB.queryDocumentsPublisher(at: devicesPath, query: [
					.isAnyOf(.init([4,1]), key: "something")
				], options: .init(limit: .max))
				
				var docsIsAnyOfCount = 0
				
				_ = docsIsAnyOf.sink(receiveCompletion: { (completion) in
					expectationPublishers.fulfill()
				}, receiveValue: { doc in
					XCTAssertTrue([4,1].contains((doc["something"] as! Int)))
					docsIsAnyOfCount += 1
				})
				
				XCTAssertEqual(docsIsAnyOfCount, 2)
				
				try? fileManager.removeItem(at: rootFolder)
			} catch {
				XCTFail("\(error)")
				try? fileManager.removeItem(at: rootFolder)
			}
			
			self.wait(for: [expectationPublishers], timeout: 5)
		}
		#endif
	}
	
	// MARK: - Convenience
	
	private func serializeDocs(serializer: DocDBSerializer, iterations: Int) {
		do {
			let docDB = DocDB(rootFolder: rootFolder, options: .init(maxFolderDepth: 8, serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			if let enumerator = try? docDB.enumerator(at: devicesPath, includeFolders: true) {
				for docPath in enumerator {
					try docDB.deleteDocument(at: docPath)
				}
			}
			
			for i in 0..<iterations {
				try docDB.addDocument(at: try devicesPath.appending("device\(i).data"), dictionary: [
					"os": "iOS",
					"version": "13.\(i)",
					"something": 1,
					"test1": 12,
					"test2": "something",
					"testArray": [1,2,3,i,5,5,6,7,8],
					"testArray2": ["1","2","3","4","5","5","6","7","8"]
				])
			}
			
			let devices = try docDB.documents(at: devicesPath)
			XCTAssertEqual(devices.count, iterations)
			
			for docPath in try docDB.enumerator(at: devicesPath, includeFolders: true) {
				try docDB.deleteDocument(at: docPath)
			}
			
		} catch {
			XCTFail("\(error)")
		}
	}
	
	// MARK: - All tests
	
	
	static var allTests = [
		("testSavingDocsAsJSON", testSavingDocsAsJSON),
		("testUpdatingDocument", testUpdatingDocument),
		("testMeasureSavingDocsAsJSON", testMeasureSavingDocsAsJSON),
		("testMeasureSavingBinaryDocs", testMeasureSavingBinaryDocs),
		("testQuery", testQuery),
		("testQueryIterator", testQueryIterator),
		("testQueryPublisher", testQueryPublisher)
	]
}
#endif
