#if !os(watchOS)
import XCTest
@testable import DocDB

final class DocDBTests: XCTestCase {
	
	let rootFolder = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent("doc.db")
	lazy var lowDocDB = LowDocDB(rootFolder: rootFolder, options: .init(maxDepth: 8))
	
	func testSavingDocsAsJSON() {
		do {
			let docDB = DocDB(lowDocDB: lowDocDB, options: .init(serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			if let enumerator = try? docDB.enumerator(at: devicesPath, includeFolders: true) {
				for docPath in enumerator {
					print(docPath)
					try docDB.deleteDocument(at: docPath)
				}
			}
			
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
				print("-", docPath)
				try docDB.deleteDocument(at: docPath)
			}
		} catch {
			XCTFail("\(error)")
		}
	}
	
	func testUpdatingDocument() {
		do {
			let docDB = DocDB(lowDocDB: lowDocDB, options: .init(serializer: JSONSerializationDocDBSerializer()))
			
			let devicesPath = try DocPath("/devices")
			
			if let enumerator = try? docDB.enumerator(at: devicesPath, includeFolders: true) {
				for docPath in enumerator {
					print(docPath)
					try docDB.deleteDocument(at: docPath)
				}
			}
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
				print("-", docPath)
				try docDB.deleteDocument(at: docPath)
			}
		} catch {
			XCTFail("\(error)")
		}
	}
	
	func testMeasureSavingDocsAsJSON() {
		measure {
			serializeDocs(serializer: JSONSerializationDocDBSerializer(), iterations: 1000)
		}
	}
	
	func testMeasureSavingBinaryDocs() {
		measure {
			serializeDocs(serializer: NSKeyedArchiverDocDBSerializer(), iterations: 1000)
		}
	}
	
	private func serializeDocs(serializer: DocDBSerializer, iterations: Int) {
		do {
			let docDB = DocDB(lowDocDB: lowDocDB, options: .init(serializer: serializer))
			
			let devicesPath = try DocPath("/devices")
			
			if let enumerator = try? docDB.enumerator(at: devicesPath, includeFolders: true) {
				for docPath in enumerator {
					print(docPath)
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
				print("-", docPath)
				try docDB.deleteDocument(at: docPath)
			}
			
		} catch {
			XCTFail("\(error)")
		}
	}
	
	static var allTests = [
		("testMeasureSavingDocsAsJSON", testMeasureSavingDocsAsJSON),
		("testMeasureSavingBinaryDocs", testMeasureSavingBinaryDocs)
	]
}
#endif
