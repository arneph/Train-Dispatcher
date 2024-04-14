//
//  Path_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/11/24.
//

import XCTest

@testable import Base

final class FinitePath_Tests: XCTestCase {

    func testSplitsLinearPathIntoThreeParts() {
        let originalPath = LinearPath(
            start: Point(x: 1.0.m, y: 1.0.m), end: Point(x: 51.0.m, y: 1.0.m))!
        let result = originalPath.split(at: 15.0.m, and: 35.0.m)
        XCTAssertNotNil(result)

        let (partA, partB, partC) = result!
        XCTAssertEqual(
            partA,
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m),
                    end: Point(x: 16.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            partB,
            .linear(
                LinearPath(
                    start: Point(x: 16.0.m, y: 1.0.m),
                    end: Point(x: 36.0.m, y: 1.0.m))!)
        )
        XCTAssertEqual(
            partC,
            .linear(
                LinearPath(
                    start: Point(x: 36.0.m, y: 1.0.m),
                    end: Point(x: 51.0.m, y: 1.0.m))!)
        )
    }

    func testSplitsCircularPathIntoThreeParts() {
        let originalPath = CircularPath(
            center: Point(x: 12.3.m, y: 45.6.m),
            radius: 98.7.m,
            startAngle: CircleAngle(120.0.deg),
            endAngle: CircleAngle(230.0.deg),
            direction: .positive)!
        let result = originalPath.split(at: 98.7.m * 30.0.deg, and: 98.7.m * 70.0.deg)
        XCTAssertNotNil(result)

        let (partA, partB, partC) = result!
        XCTAssertEqual(
            partA,
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(120.0.deg),
                    endAngle: CircleAngle(150.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            partB,
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(150.0.deg),
                    endAngle: CircleAngle(190.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            partC,
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(190.0.deg),
                    endAngle: CircleAngle(230.0.deg),
                    direction: .positive)!))
    }

    func testSplitsCompoundPathIntoThreeParts() {
        let originalPath = CompoundPath(components: [
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m), end: Point(x: 51.0.m, y: 1.0.m))!),
            .circular(
                CircularPath(
                    center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(270.0.deg), endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!),
        ])!
        let result = originalPath.split(at: 40.0.m, and: 50.0.m + 100.0.m * 30.0.deg)
        XCTAssertNotNil(result)

        let (partA, partB, partC) = result!
        XCTAssertEqual(
            partA,
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m),
                    end: Point(x: 41.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            partB,
            .compound(
                CompoundPath(components: [
                    .linear(
                        LinearPath(
                            start: Point(x: 41.0.m, y: 1.0.m), end: Point(x: 51.0.m, y: 1.0.m))!),
                    .circular(
                        CircularPath(
                            center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                            startAngle: CircleAngle(270.0.deg), endAngle: CircleAngle(300.0.deg),
                            direction: .positive)!),
                ])!))
        XCTAssertEqual(
            partC,
            .circular(
                CircularPath(
                    center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(300.0.deg), endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!))
    }

}

final class SomeFinitePath_Tests: XCTestCase {

    func testCombinesCircularPaths() {
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(90.0.deg), deltaAngle: 14.0.deg)!)),
            .circular(
                CircularPath(
                    center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                    startAngle: CircleAngle(47.0.deg), deltaAngle: 57.0.deg)!))
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 21.0.m), radius: 19.0.m,
                        startAngle: CircleAngle(90.0.deg), deltaAngle: 14.0.deg)!)),
            .compound(
                CompoundPath(components: [
                    .circular(
                        CircularPath(
                            center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                            startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                    .circular(
                        CircularPath(
                            center: Point(x: 7.0.m, y: 21.0.m), radius: 19.0.m,
                            startAngle: CircleAngle(90.0.deg), deltaAngle: 14.0.deg)!),
                ])!))
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(105.0.deg), deltaAngle: 14.0.deg)!)), nil)
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(90.0.deg), deltaAngle: -14.0.deg)!)), nil)
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 777.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(90.0.deg), deltaAngle: 14.0.deg)!)), nil)
        XCTAssertEqual(
            SomeFinitePath.combine(
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 29.0.m,
                        startAngle: CircleAngle(47.0.deg), deltaAngle: 43.0.deg)!),
                .circular(
                    CircularPath(
                        center: Point(x: 7.0.m, y: 11.0.m), radius: 31.0.m,
                        startAngle: CircleAngle(90.0.deg), deltaAngle: 14.0.deg)!)), nil)
    }

}
