import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(StreamSocket_UnitTests.allTests),
    ]
}
#endif
