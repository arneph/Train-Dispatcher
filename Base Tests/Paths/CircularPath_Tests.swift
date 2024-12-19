//
//  CircularPath_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/18/24.
//

import XCTest

@testable import Base

final class CircularPath_Tests: XCTestCase {

    func testDeterminesIfDistanceIsAboveRequirement() {
        XCTAssertTrue(
            CircularPath.isDistance(
                between: CircularPath(
                    center: Point(x: 10.0.m, y: 10.0.m),
                    radius: 5.0.m,
                    startAngle: CircleAngle(-45.0.deg),
                    deltaAngle: 120.0.deg)!,
                and: CircularPath(
                    center: Point(x: 30.0.m, y: 10.0.m),
                    radius: 11.0.m,
                    startAngle: CircleAngle(135.0.deg),
                    deltaAngle: 120.0.deg)!,
                above: 3.0.m))
        XCTAssertFalse(
            CircularPath.isDistance(
                between: CircularPath(
                    center: Point(x: 10.0.m, y: 10.0.m),
                    radius: 5.0.m,
                    startAngle: CircleAngle(-45.0.deg),
                    deltaAngle: 120.0.deg)!,
                and: CircularPath(
                    center: Point(x: 30.0.m, y: 10.0.m),
                    radius: 11.0.m,
                    startAngle: CircleAngle(135.0.deg),
                    deltaAngle: 120.0.deg)!,
                above: 15.0.m))
        XCTAssertTrue(
            CircularPath.isDistance(
                between: CircularPath(
                    center: Point(x: 10.0.m, y: 10.0.m),
                    radius: 5.0.m,
                    startAngle: CircleAngle(135.0.deg),
                    deltaAngle: 120.0.deg)!,
                and: CircularPath(
                    center: Point(x: 30.0.m, y: 10.0.m),
                    radius: 11.0.m,
                    startAngle: CircleAngle(-45.0.deg),
                    deltaAngle: 120.0.deg)!,
                above: 15.0.m))
        XCTAssertFalse(
            CircularPath.isDistance(
                between: CircularPath(
                    center: Point(x: 10.0.m, y: 10.0.m),
                    radius: 5.0.m,
                    startAngle: CircleAngle(135.0.deg),
                    deltaAngle: 120.0.deg)!,
                and: CircularPath(
                    center: Point(x: 30.0.m, y: 10.0.m),
                    radius: 11.0.m,
                    startAngle: CircleAngle(-45.0.deg),
                    deltaAngle: 120.0.deg)!,
                above: 30.0.m))
    }

}
