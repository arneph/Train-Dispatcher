//
//  Code_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 12/3/23.
//

import Train_Dispatcher
import XCTest

final class Code_Tests: XCTestCase {
    
    func testScansColon() {
        let text: String = ":"
        let scanner = Scanner(for: text)
        
        XCTAssertEqual(scanner.token, .colon)
        XCTAssertEqual(scanner.tokenRange, text.startIndex...text.index(before: text.endIndex))
        XCTAssertEqual(scanner.tokenText, ":")
        
        XCTAssertEqual(scanner.next(), .end)
        XCTAssertEqual(scanner.token, .end)
        XCTAssertEqual(scanner.tokenRange, text.endIndex...text.endIndex)
        XCTAssertEqual(scanner.tokenText, "")
    }
    
}
