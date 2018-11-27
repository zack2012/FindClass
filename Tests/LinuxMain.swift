import XCTest

import findclassTests

var tests = [XCTestCaseEntry]()
tests += findclassTests.allTests()
XCTMain(tests)