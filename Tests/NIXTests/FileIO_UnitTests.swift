import Foundation
import XCTest
@testable import NIX

// -------------------------------------
class FileIO_UnitTests: XCTestCase
{
    static var allTests =
    [
        ("test_write_writes_data_to_file", test_write_writes_data_to_file),
        ("test_read_reads_back_data_written_to_file", test_read_reads_back_data_written_to_file),
        ("test_readv_scatters_data_into_buffers_array", test_readv_scatters_data_into_buffers_array),
    ]
    
    // -------------------------------------
    func makeFileName(from callingFunction: StaticString = #function) -> String
    {
        return "\(callingFunction)-test-data"
    }
    
    // -------------------------------------
    func createDataFile(
        from src: Data,
        callingFunction: StaticString = #function,
        file: StaticString = #file,
        line: UInt = #line)
            -> (file: NIX.IODescriptor, cleanUp: () -> Void)
    {
        let filename = makeFileName(from: callingFunction)
        _ = unlink(filename) // clean up from previous test run
        let fd = open(filename, O_RDWR | O_CREAT)
        if fd < 0
        {
            fatalError(
                "Failed to create data file: \(Error())",
                file: file,
                line: line
            )
        }
        
        let fileDesc = FileDescriptor(fd)
        
        if src.count > 0
        {
            switch write(fileDesc, src)
            {
                case .success(let bytesWritten):
                    XCTAssertEqual(
                        bytesWritten, src.count,
                        "Some test data not written to file.",
                        file: file,
                        line: line
                    )
                case .failure(let error):
                    XCTFail(
                        "Error writing test data: \(error)",
                        file: file,
                        line: line
                    )
            }
            
            if HostOS.lseek(fd, 0, SEEK_SET) < 0 {
                XCTFail(
                    "Failed to seek beginning of file: \(HostOS.errno)",
                    file: file,
                    line: line
                )
            }
        }
        
        return (fileDesc, {_ = close(fd); _ = unlink(filename) })
    }
    
    // -------------------------------------
    func test_write_writes_data_to_file()
    {
        let testData = Data((0..<100).map { $0 })
        let (file, cleanup) = createDataFile(from: Data())
        defer { cleanup() }
        
        // Now we're set up for the actual test
        switch NIX.write(file, testData)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(bytesWritten, testData.count)
            case .failure(let error):
                XCTFail("Error on write: \(error)")
        }
        
        if HostOS.lseek(file.descriptor, 0, SEEK_SET) < 0 {
            XCTFail("Seek failed")
        }
        
        // Intentionally use Foundation to read data.  The NIX.read test relies
        // on NIX.write working.  We don't want this NIX.write test to rely on
        // NIX.read as well.  We could use HostOS.read, but Foundaation's
        // FileHandle already supports reading into Data, so we can avoid
        // having to deal with pointers in this test.
        let f = Foundation.FileHandle(fileDescriptor: file.descriptor)
        guard let readBackBuffer = try? f.readToEnd() else {
            XCTFail("Failed to read back data")
            return
        }
        
        XCTAssertEqual(readBackBuffer, testData)
    }
    
    // -------------------------------------
    func test_read_reads_back_data_written_to_file()
    {
        let testData = Data((0..<100).map { $0 })
        let (file, cleanup) = createDataFile(from: testData)
        defer { cleanup() }
        
        // Now we're set up for the actual test
        var buffer = Data(repeating: 0, count: testData.count)
        
        switch NIX.read(file, &buffer)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, testData.count)
            case .failure(let error):
                XCTFail("Error on read: \(error)")
        }
        
        XCTAssertEqual(buffer, testData)
    }
    
    // -------------------------------------
    func test_readv_scatters_data_into_buffers_array()
    {
        let testData = Data((0..<100).map { $0 })
        let (file, cleanup) = createDataFile(from: testData)
        defer { cleanup() }
        
        // Now we're set up for the actual test
        var buffers = (0..<5).map { _ in Data(repeating: 0, count: 20) }
        
        switch NIX.readv(file, &buffers)
        {
            case .success(let bytesRead):
                XCTAssertEqual(bytesRead, testData.count)
            case .failure(let error):
                XCTFail("Error on readv: \(error)")
        }
        
        var allData = Data(capacity: testData.count)
        for data in buffers {
            allData.append(contentsOf: data)
        }
        
        XCTAssertEqual(allData, testData)
    }
}
