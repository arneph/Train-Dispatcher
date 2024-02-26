//
//  Geometry_Test.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/16/24.
//

@testable import Train_Dispatcher

import XCTest

final class Geometry_Tests: XCTestCase {
    
    func testFindsClosestPointOnLineThroughTwoPoints() {
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          andThrough: Point(x: 0.0.m, y: 0.0.m),
                                          to: Point(x: -20.0.m, y: 5.0.m)),
                       Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          andThrough: Point(x: 0.0.m, y: 0.0.m),
                                          to: Point(x: -70.0.m, y: -15.0.m)),
                       Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          andThrough: Point(x: 0.0.m, y: 0.0.m),
                                          to: Point(x: +20.0.m, y: 55.0.m)),
                       Point(x: +20.0.m, y: 0.0.m))
    }
    
    func testFindsClosestPointOnLineThroughPointWithDirection() {
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withDirection: Direction(x: 123.0.m, y: 0.0.m),
                                          to: Point(x: -20.0.m, y: 5.0.m)),
                       Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withDirection: Direction(x: 123.0.m, y: 0.0.m),
                                          to: Point(x: -70.0.m, y: -15.0.m)),
                       Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withDirection: Direction(x: 123.0.m, y: 0.0.m),
                                          to: Point(x: +20.0.m, y: 55.0.m)),
                       Point(x: +20.0.m, y: 0.0.m))
    }
    
    func testFindsClosestPointOnLineThroughPointWithOrientation() {
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withOrientation: 0.0.deg,
                                          to: Point(x: -20.0.m, y: 5.0.m)),
                       Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withOrientation: 0.0.deg,
                                          to: Point(x: -70.0.m, y: -15.0.m)),
                       Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(closestPointOnLine(through: Point(x: -50.0.m, y: 0.0.m),
                                          withOrientation: 0.0.deg,
                                          to: Point(x: +20.0.m, y: 55.0.m)),
                       Point(x: +20.0.m, y: 0.0.m))
    }
    
}
