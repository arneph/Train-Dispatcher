//
//  Geometry_Test.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/16/24.
//

import XCTest

@testable import Base

final class Geometry_Tests: XCTestCase {

    func testFindsClosestPointOnLineThroughTwoPoints() {
        XCTAssertEqual(
            Line(through: Point(x: -50.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: -20.0.m, y: 5.0.m)), Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(through: Point(x: -50.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: -70.0.m, y: -15.0.m)), Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(through: Point(x: -50.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: +20.0.m, y: 55.0.m)), Point(x: +20.0.m, y: 0.0.m))
    }

    func testFindsClosestPointOnLineThroughPointWithDirection() {
        XCTAssertEqual(
            Line(base: Point(x: -50.0.m, y: 0.0.m), direction: Direction(x: 123.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: -20.0.m, y: 5.0.m)), Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(base: Point(x: -50.0.m, y: 0.0.m), direction: Direction(x: 123.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: -70.0.m, y: -15.0.m)), Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(base: Point(x: -50.0.m, y: 0.0.m), direction: Direction(x: 123.0.m, y: 0.0.m))!
                .closestPoint(to: Point(x: +20.0.m, y: 55.0.m)), Point(x: +20.0.m, y: 0.0.m))
    }

    func testFindsClosestPointOnLineThroughPointWithOrientation() {
        XCTAssertEqual(
            Line(
                base: Point(x: -50.0.m, y: 0.0.m), orientation: 0.0.deg
            )
            .closestPoint(to: Point(x: -20.0.m, y: 5.0.m)), Point(x: -20.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(
                base: Point(x: -50.0.m, y: 0.0.m), orientation: 0.0.deg
            )
            .closestPoint(to: Point(x: -70.0.m, y: -15.0.m)), Point(x: -70.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line(
                base: Point(x: -50.0.m, y: 0.0.m), orientation: 0.0.deg
            )
            .closestPoint(to: Point(x: +20.0.m, y: 55.0.m)), Point(x: +20.0.m, y: 0.0.m))
    }

    func testFindsLineIntersection() {
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!),
            Point(x: 0.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: -1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!),
            Point(x: 0.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: -1.0.m))!),
            Point(x: 0.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: -1.0.m, y: 0.0.m), and: Point(x: +1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: -1.0.m), and: Point(x: 0.0.m, y: +1.0.m))!),
            Point(x: 0.0.m, y: 0.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!),
            Point(x: +8.0.m, y: +7.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!),
            Point(x: 3.5.m, y: 5.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!),
            Point(x: 3.5.m, y: 5.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 5.0.m, y: 11.0.m), and: Point(x: 4.0.m, y: 7.0.m))!),
            Point(x: 3.5.m, y: 5.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 5.0.m, y: 11.0.m), and: Point(x: 4.0.m, y: 7.0.m))!),
            Point(x: 3.5.m, y: 5.0.m))
        XCTAssertEqual(
            Line.intersection(
                Line(through: Point(x: -11.0.m, y: -2.0.m), and: Point(x: -6.0.m, y: -4.0.m))!,
                Line(through: Point(x: -5.0.m, y: -11.0.m), and: Point(x: -4.0.m, y: -7.0.m))!),
            Point(x: -3.5.m, y: -5.0.m))
    }

    func testFindsNoIntersectionForParallelLines() {
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 3.0.m), and: Point(x: 1.0.m, y: 3.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 10.0.m, y: 7.0.m), and: Point(x: 11.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: -8.0.m, y: 0.0.m), and: Point(x: -8.0.m, y: 1.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 22.0.m, y: 0.0.m), and: Point(x: 22.0.m, y: 1.0.m))!,
                Line(through: Point(x: 19.0.m, y: 10.0.m), and: Point(x: 19.0.m, y: 11.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: -5.0.m, y: -7.0.m), and: Point(x: +23.0.m, y: -7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: -5.0.m, y: -7.0.m), and: Point(x: +23.0.m, y: -7.0.m))!,
                Line(through: Point(x: +5.0.m, y: +7.0.m), and: Point(x: -23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: -8.0.m, y: +2.0.m), and: Point(x: -8.0.m, y: +9.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: -8.0.m, y: +2.0.m), and: Point(x: -8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: -2.0.m), and: Point(x: +8.0.m, y: -9.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 1.0.m, y: 7.0.m), and: Point(x: 6.0.m, y: 5.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 5.0.m), and: Point(x: 6.0.m, y: 3.0.m))!,
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 2.0.m, y: 3.0.m), and: Point(x: 3.0.m, y: 7.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 7.0.m, y: 15.0.m), and: Point(x: 5.0.m, y: 7.0.m))!))
    }

    func testFindsNoIntersectionForCoincidentLines() {
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 10.0.m, y: 0.0.m), and: Point(x: 11.0.m, y: 0.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: 0.0.m, y: 10.0.m), and: Point(x: 0.0.m, y: 11.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: +5.0.m, y: +7.0.m), and: Point(x: -23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: -2.0.m), and: Point(x: +8.0.m, y: -9.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.intersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 6.0.m, y: 15.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
    }

}
