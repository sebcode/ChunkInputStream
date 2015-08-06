//
//  ChunkInputStreamTests.swift
//  ChunkInputStreamTests
//
//  Created by Sebastian Volland on 06/08/15.
//  Copyright © 2015 Sebastian Volland. All rights reserved.
//

import XCTest

class ChunkInputStreamTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func createTempFile(prefix: String = "tmpfile") -> String {
        let uuid: CFUUIDRef = CFUUIDCreate(nil)
        let uuidString = CFUUIDCreateString(nil, uuid)
        let name = NSTemporaryDirectory().stringByAppendingPathComponent("\(prefix)-\(uuidString)")
        return name
    }

    func filePutContents(file: String, contents: String) {
        guard let data = contents.dataUsingEncoding(NSUTF8StringEncoding) else {
            return
        }

        NSFileManager.defaultManager().createFileAtPath(file, contents: data, attributes: nil)
    }

    func testExample() {
        let tmpFile = createTempFile()
        let testData = "HELLO123TEST"
        let testDataLen = UInt(testData.lengthOfBytesUsingEncoding(NSASCIIStringEncoding))
        filePutContents(tmpFile, contents: testData)

        let bufSize = 1
        var buf = [UInt8](count: bufSize, repeatedValue: 0)

        // Read full stream

        var fileInputStream = NSInputStream(fileAtPath: tmpFile)
        var inputStream = ChunkInputStream(inputStream: fileInputStream)
        inputStream.startPosition = 0
        inputStream.readMax = testDataLen
        inputStream.open()

        var readData = NSMutableData()
        var bytesRead = 0
        repeat {
            bytesRead = inputStream.read(&buf, maxLength: bufSize)
            if bytesRead > 0 {
                readData.appendBytes(buf, length: bytesRead)
            }
        } while bytesRead > 0

        XCTAssertEqual(testDataLen, UInt(readData.length))
        XCTAssertEqual(testData, String(NSString(data: readData, encoding: NSASCIIStringEncoding)!))

        // Read part of stream

        fileInputStream = NSInputStream(fileAtPath: tmpFile)
        inputStream = ChunkInputStream(inputStream: fileInputStream)
        inputStream.startPosition = 5
        inputStream.readMax = 3
        inputStream.open()

        readData = NSMutableData()
        bytesRead = 0
        repeat {
            bytesRead = inputStream.read(&buf, maxLength: bufSize)
            if bytesRead > 0 {
                readData.appendBytes(buf, length: bytesRead)
            }
        } while bytesRead > 0

        XCTAssertEqual(3, UInt(readData.length))
        XCTAssertEqual("123", String(NSString(data: readData, encoding: NSASCIIStringEncoding)!))

        try! NSFileManager.defaultManager().removeItemAtPath(tmpFile)
    }

}
