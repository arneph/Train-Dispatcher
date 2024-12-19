//
//  LinearPath_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/18/24.
//

import XCTest

@testable import Base

final class LinearPath_Tests: XCTestCase {

    func testDeterminesIfDistanceIsAboveRequirement() {
        XCTAssertFalse(
            LinearPath.isDistance(
                between: LinearPath(
                    start: Point(x: -10.0.m, y: -10.m), end: Point(x: -10.0.m, y: 5.0.m))!,
                and: LinearPath(
                    start: Point(x: -15.0.m, y: -15.0.m), end: Point(x: 25.0.m, y: 25.0.m))!,
                above: 0.5.m))
        XCTAssertTrue(
            LinearPath.isDistance(
                between: LinearPath(
                    start: Point(x: -10.0.m, y: -10.0.m), end: Point(x: -10.0.m, y: 0.0.m))!,
                and: LinearPath(
                    start: Point(x: 5.0.m, y: -5.0.m), end: Point(x: 25.0.m, y: -5.0.m))!,
                above: 14.0.m))
        XCTAssertFalse(
            LinearPath.isDistance(
                between: LinearPath(
                    start: Point(x: -10.0.m, y: -10.m), end: Point(x: -10.0.m, y: 0.0.m))!,
                and: LinearPath(
                    start: Point(x: 5.0.m, y: -5.0.m), end: Point(x: 25.0.m, y: -5.0.m))!,
                above: 16.0.m))
        XCTAssertTrue(
            LinearPath.isDistance(
                between: LinearPath(
                    start: Point(x: -10.0.m, y: -25.0.m), end: Point(x: 10.0.m, y: -5.0.m))!,
                and: LinearPath(
                    start: Point(x: -5.0.m, y: -5.0.m), end: Point(x: -25.0.m, y: -25.0.m))!,
                above: 10.0.m))
        XCTAssertFalse(
            LinearPath.isDistance(
                between: LinearPath(
                    start: Point(x: -10.0.m, y: -25.0.m), end: Point(x: 10.0.m, y: -5.0.m))!,
                and: LinearPath(
                    start: Point(x: -5.0.m, y: -5.0.m), end: Point(x: -25.0.m, y: -25.0.m))!,
                above: 11.0.m))
    }

}
