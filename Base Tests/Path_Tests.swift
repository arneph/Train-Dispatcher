//
//  Path_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/11/24.
//

import XCTest

@testable import Base

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
