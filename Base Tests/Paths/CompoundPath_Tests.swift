//
//  CompoundPath_Tests.swift
//  Base Tests
//
//  Created by Arne Philipeit on 12/18/24.
//

import XCTest

@testable import Base

final class CompoundPath_Tests: XCTestCase {

    func testDeterminesIfDistanceIsAboveRequirement() {
        let pathA = CompoundPath(components: [
            .linear(
                LinearPath(
                    start: Point(x: 0.0.m, y: -50.0.m),
                    end: Point(x: 0.0.m, y: 0.0.m))!),
            .circular(
                CircularPath(
                    center: Point(x: 80.0.m, y: 0.0.m),
                    radius: 80.0.m,
                    startAngle: CircleAngle(180.0.deg),
                    deltaAngle: -30.0.deg)!),
        ])!
        let pathB = CompoundPath(components: [
            .linear(
                LinearPath(
                    start: Point(x: 5.0.m, y: -80.0.m),
                    end: Point(x: 5.0.m, y: 0.0.m))!),
            .circular(
                CircularPath(
                    center: Point(x: 80.0.m, y: 0.0.m),
                    radius: 75.0.m,
                    startAngle: CircleAngle(180.0.deg),
                    deltaAngle: -60.0.deg)!),
        ])!
        XCTAssertTrue(CompoundPath.isDistance(between: pathA, and: pathB, above: 4.0.m))
        XCTAssertFalse(CompoundPath.isDistance(between: pathA, and: pathB, above: 6.0.m))
    }

}
