import Foundation
import XCTest
@testable import NIX

// -------------------------------------
class FileIO_UnitTests: XCTestCase
{
    // -------------------------------------
    func test_readv_scatters_data_into_buffers_array()
    {
        let testData = Data((0..<100).map { $0 })
        let filename = "\(#function)-test-data"
        let fd = open(filename, O_RDWR | O_CREAT)
        XCTAssertGreaterThan(fd, 0, "Failed to create data file")
        defer
        {
            _ = close(fd)
            _ = unlink(filename)
        }
        
        let file = FileDescriptor(fd)
        
        switch write(file, testData)
        {
            case .success(let bytesWritten):
                XCTAssertEqual(
                    bytesWritten, testData.count,
                    "Some test data not written to file."
                )
            case .failure(let error):
                XCTFail("Error writing test data: \(error)")
        }
        
        if HostOS.lseek(fd, 0, SEEK_SET) < 0 {
            XCTFail("Failed to seek beginning of file: \(HostOS.errno)")
        }
        
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
