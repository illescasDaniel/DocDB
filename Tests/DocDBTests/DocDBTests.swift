#if !os(watchOS)
import XCTest
@testable import DocDB

final class DocDBTests: XCTestCase {
	
	let rootFolder = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent("doc")
	lazy var lowDocDB = LowDocDB(rootFolder: rootFolder, options: .init(maxDepth: 8))

    func testMeasureSavingDocsAsJSON() {
		measure {
			measureSerializer(serializer: JSONSerializationDocDBSerializer())
		}
    }

	func testMeasureSavingBinaryDocs() {
		measure {
			measureSerializer(serializer: NSKeyedArchiverDocDBSerializer())
		}
    }

	func measureSerializer(serializer: DocDBSerializer) {
		do {
			let docDB = DocDB(lowDocDB: lowDocDB, options: .init(serializer: serializer))

			let devicesPath = try DocPath("/devices")

			for docPath in try docDB.enumerator(at: devicesPath) {
				try docDB.deleteDocument(at: docPath)
			}

			for i in 0..<1000 {
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
			XCTAssertEqual(devices.count, 1000)

			for docPath in try docDB.enumerator(at: devicesPath) {
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
