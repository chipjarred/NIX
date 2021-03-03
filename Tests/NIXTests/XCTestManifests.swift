import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry]
{
    return [
        testCase(FileIO_UnitTests.allTests),
        testCase(StreamSocket_UnitTests.allTests),
        testCase(DatagramSocket_UnitTests.allTests),
    ]
}
#endif
