//
//  Units_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/3/24.
//

import XCTest

@testable import Base

final class ReduceRanges_Tests: XCTestCase {

    func testHandlesNoRanges() {
        XCTAssertEqual(reduce(ranges: [ClosedRange<Distance>]()), [])
    }

    func testHandlesSingleRange() {
        XCTAssertEqual(reduce(ranges: [2.0.m...7.0.m]), [2.0.m...7.0.m])
    }

    func testHandlesTwoAdjacentRanges() {
        XCTAssertEqual(reduce(ranges: [2.0.m...7.0.m, 7.0.m...11.0.m]), [2.0.m...11.0.m])
        XCTAssertEqual(reduce(ranges: [7.0.m...11.0.m, 2.0.m...7.0.m]), [2.0.m...11.0.m])
    }

    func testHandlesTwoDisjointRanges() {
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 11.0.m...15.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 2.0.m...7.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m])
    }

    func testHandlesTwoOverlappingRanges() {
        XCTAssertEqual(reduce(ranges: [2.0.m...7.0.m, 5.0.m...11.0.m]), [2.0.m...11.0.m])
        XCTAssertEqual(reduce(ranges: [5.0.m...11.0.m, 2.0.m...7.0.m]), [2.0.m...11.0.m])
    }

    func testHandlesTwoIdenticalRanges() {
        XCTAssertEqual(reduce(ranges: [2.0.m...7.0.m, 2.0.m...7.0.m]), [2.0.m...7.0.m])
    }

    func testHandlesOneRangeContainedInAnotherRange() {
        XCTAssertEqual(reduce(ranges: [2.0.m...7.0.m, 3.0.m...6.0.m]), [2.0.m...7.0.m])
        XCTAssertEqual(reduce(ranges: [3.0.m...6.0.m, 2.0.m...7.0.m]), [2.0.m...7.0.m])
    }

    func testHandlesThreeAdjacentRanges() {
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 7.0.m...11.0.m, 11.0.m...15.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [7.0.m...11.0.m, 2.0.m...7.0.m, 11.0.m...15.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 11.0.m...15.0.m, 7.0.m...11.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [7.0.m...11.0.m, 11.0.m...15.0.m, 2.0.m...7.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 2.0.m...7.0.m, 7.0.m...11.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 7.0.m...11.0.m, 2.0.m...7.0.m]),
            [2.0.m...15.0.m])
    }

    func testHandlesThreeDisjointRanges() {
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 2.0.m...7.0.m, 19.0.m...24.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 19.0.m...24.0.m, 11.0.m...15.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 19.0.m...24.0.m, 2.0.m...7.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
        XCTAssertEqual(
            reduce(ranges: [19.0.m...24.0.m, 2.0.m...7.0.m, 11.0.m...15.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
        XCTAssertEqual(
            reduce(ranges: [19.0.m...24.0.m, 11.0.m...15.0.m, 2.0.m...7.0.m]),
            [2.0.m...7.0.m, 11.0.m...15.0.m, 19.0.m...24.0.m])
    }

    func testHandlesThreeOverlappingRanges() {
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 5.0.m...12.0.m, 11.0.m...15.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [5.0.m...12.0.m, 2.0.m...7.0.m, 11.0.m...15.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [2.0.m...7.0.m, 11.0.m...15.0.m, 5.0.m...12.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [5.0.m...12.0.m, 11.0.m...15.0.m, 2.0.m...7.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 2.0.m...7.0.m, 5.0.m...12.0.m]),
            [2.0.m...15.0.m])
        XCTAssertEqual(
            reduce(ranges: [11.0.m...15.0.m, 5.0.m...12.0.m, 2.0.m...7.0.m]),
            [2.0.m...15.0.m])
    }

    func testHandlesSeveralRanges() {
        XCTAssertEqual(
            reduce(ranges: [
                2.0.m...7.0.m,
                3.0.m...6.0.m,
                4.0.m...8.0.m,
                9.0.m...11.0.m,
                10.0.m...15.0.m,
                12.0.m...15.0.m,
                15.0.m...17.0.m,
                21.0.m...24.0.m,
                25.0.m...29.0.m,
            ]),
            [
                2.0.m...8.0.m,
                9.0.m...17.0.m,
                21.0.m...24.0.m,
                25.0.m...29.0.m,
            ])
        XCTAssertEqual(
            reduce(ranges: [
                9.0.m...11.0.m,
                21.0.m...24.0.m,
                25.0.m...29.0.m,
                12.0.m...15.0.m,
                10.0.m...15.0.m,
                4.0.m...8.0.m,
                2.0.m...7.0.m,
                3.0.m...6.0.m,
                15.0.m...17.0.m,
            ]),
            [
                2.0.m...8.0.m,
                9.0.m...17.0.m,
                21.0.m...24.0.m,
                25.0.m...29.0.m,
            ])
        XCTAssertEqual(
            reduce(ranges: [
                3.0.m...6.0.m,
                10.0.m...15.0.m,
                21.0.m...24.0.m,
                9.0.m...11.0.m,
                4.0.m...8.0.m,
                15.0.m...17.0.m,
                25.0.m...29.0.m,
                12.0.m...15.0.m,
                2.0.m...7.0.m,
            ]),
            [
                2.0.m...8.0.m,
                9.0.m...17.0.m,
                21.0.m...24.0.m,
                25.0.m...29.0.m,
            ])
    }

}
