//
//  Geometry_Test.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/16/24.
//

import XCTest

@testable import Base

final class Angle_Test: XCTestCase {

    func testIsHorizontal() {
        XCTAssertTrue(0.0.deg.isHorizontal)
        XCTAssertTrue((+180.0.deg).isHorizontal)
        XCTAssertTrue((-180.0.deg).isHorizontal)
        XCTAssertTrue((+540.0.deg).isHorizontal)
        XCTAssertTrue((-540.0.deg).isHorizontal)
        XCTAssertFalse((+1.0.deg).isHorizontal)
        XCTAssertFalse((-1.0.deg).isHorizontal)
        XCTAssertFalse((+100.0.deg).isHorizontal)
        XCTAssertFalse((-100.0.deg).isHorizontal)
        XCTAssertFalse((+90.0.deg).isHorizontal)
        XCTAssertFalse((-90.0.deg).isHorizontal)
        XCTAssertFalse((+270.0.deg).isHorizontal)
        XCTAssertFalse((-270.0.deg).isHorizontal)
        XCTAssertFalse((+450.0.deg).isHorizontal)
        XCTAssertFalse((-450.0.deg).isHorizontal)
    }

    func testIsVertical() {
        XCTAssertFalse(0.0.deg.isVertical)
        XCTAssertFalse((+180.0.deg).isVertical)
        XCTAssertFalse((-180.0.deg).isVertical)
        XCTAssertFalse((+540.0.deg).isVertical)
        XCTAssertFalse((-540.0.deg).isVertical)
        XCTAssertFalse((+1.0.deg).isVertical)
        XCTAssertFalse((-1.0.deg).isVertical)
        XCTAssertFalse((+100.0.deg).isVertical)
        XCTAssertFalse((-100.0.deg).isVertical)
        XCTAssertTrue((+90.0.deg).isVertical)
        XCTAssertTrue((-90.0.deg).isVertical)
        XCTAssertTrue((+270.0.deg).isVertical)
        XCTAssertTrue((-270.0.deg).isVertical)
        XCTAssertTrue((+450.0.deg).isVertical)
        XCTAssertTrue((-450.0.deg).isVertical)
    }

}

final class Line_Tests: XCTestCase {

    func testCannotCreateLineWithNoDirection() {
        XCTAssertNil(
            Line(
                base: Point(x: 1.2.m, y: 3.4.m),
                direction: Direction(x: 0.0.m, y: 0.0.m)))
    }

    func testCannotCreateLineThroughSinglePoint() {
        XCTAssertNil(Line(through: Point(x: 1.2.m, y: 3.4.m), and: Point(x: 1.2.m, y: 3.4.m)))
    }

    func testLineReturnsPoints() {
        let line = Line(base: Point(x: 12.3.m, y: 4.56.m), orientation: 22.5.deg)
        XCTAssertEqual(line.point(at: 0.0.m), Point(x: 12.3.m, y: 4.56.m))
        XCTAssertEqual(line.point(at: +1.0.m), Point(x: 13.2238795325.m, y: 4.9426834324.m))
        XCTAssertEqual(line.point(at: -1.0.m), Point(x: 11.3761204675.m, y: 4.1773165676.m))
        XCTAssertEqual(line.point(at: +2.5.m), Point(x: 14.6096988313.m, y: 5.5167085809.m))
        XCTAssertEqual(line.point(at: -8.3.m), Point(x: 4.6317998802.m, y: 1.3837275114.m))
    }

    func testLineReturnsArgs() {
        let line = Line(base: Point(x: 12.3.m, y: 4.56.m), orientation: 22.5.deg)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 4.56.m)), 0.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 13.2238795325.m, y: 4.9426834324.m)), +1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 11.3761204675.m, y: 4.1773165676.m)), -1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 14.6096988313.m, y: 5.5167085809.m)), +2.5.m)
        XCTAssertEqual(line.arg(for: Point(x: 4.6317998802.m, y: 1.3837275114.m)), -8.3.m)
        XCTAssertNil(line.arg(for: Point(x: 12.3.m, y: 5.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 11.3.m, y: 4.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 11.3.m, y: 5.56.m)))
    }

    func testHorizontalLineReturnsArgs() {
        let line = Line(base: Point(x: 12.3.m, y: 4.56.m), orientation: -180.0.deg)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 4.56.m)), 0.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 13.3.m, y: 4.56.m)), -1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 11.3.m, y: 4.56.m)), +1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 9.8.m, y: 4.56.m)), +2.5.m)
        XCTAssertEqual(line.arg(for: Point(x: 20.8.m, y: 4.56.m)), -8.5.m)
        XCTAssertNil(line.arg(for: Point(x: 12.3.m, y: 3.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 13.3.m, y: 3.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 9.8.m, y: 3.56.m)))
    }

    func testVerticalLineReturnsArgs() {
        let line = Line(base: Point(x: 12.3.m, y: 4.56.m), orientation: -90.0.deg)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 4.56.m)), 0.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 5.56.m)), -1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 3.56.m)), +1.0.m)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: 7.06.m)), -2.5.m)
        XCTAssertEqual(line.arg(for: Point(x: 12.3.m, y: -3.94.m)), +8.5.m)
        XCTAssertNil(line.arg(for: Point(x: 11.3.m, y: 4.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 13.3.m, y: 5.56.m)))
        XCTAssertNil(line.arg(for: Point(x: 12.4.m, y: 0.0.m)))
    }

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

    func testFinsArgsForPointsOnCircle() {
        XCTAssertEqual(
            Line(
                through: Point(x: -70.0.m, y: 52.4264068712.m),
                and: Point(x: 90.0.m, y: 52.4264068712.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [37.5735931288.m, 122.4264068712.m])
        XCTAssertEqual(
            Line(
                through: Point(x: 52.4264068712.m, y: -70.0.m),
                and: Point(x: 52.4264068712.m, y: 90.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [37.5735931288.m, 122.4264068712.m])
        XCTAssertEqual(
            Line(
                through: Point(x: -50.0.m, y: 70.0.m),
                and: Point(x: 70.0.m, y: -50.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [24.8528137424.m, 144.8528137424.m])
        XCTAssertEqual(
            Line(
                through: Point(x: -50.0.m, y: -50.0.m),
                and: Point(x: 70.0.m, y: 70.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [24.8528137424.m, 144.8528137424.m])
        XCTAssertEqual(
            Line(
                through: Point(x: -12.0.m, y: 70.0.m),
                and: Point(x: 23.0.m, y: 70.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [22.0.m])
        XCTAssertEqual(
            Line(
                through: Point(x: -12.0.m, y: -50.0.m),
                and: Point(x: 23.0.m, y: -50.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [22.0.m])
        XCTAssertEqual(
            Line(
                through: Point(x: -50.0.m, y: -12.0.m),
                and: Point(x: -50.0.m, y: 23.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [22.0.m])
        XCTAssertEqual(
            Line(
                through: Point(x: +70.0.m, y: -12.0.m),
                and: Point(x: +70.0.m, y: 23.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)), [22.0.m])
        XCTAssert(
            Line(
                through: Point(x: +75.0.m, y: -12.0.m),
                and: Point(x: +75.0.m, y: 23.0.m))!.argsForPoints(
                    atDistance: 60.0.m,
                    from: Point(x: 10.0.m, y: 10.0.m)
                ).isEmpty)
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

    func testFindsArgsForLineIntersection() {
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!)! == (
                    0.0.m, 0.0.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: -1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!)! == (
                    0.0.m, 0.0.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: -1.0.m))!)! == (
                    0.0.m, 0.0.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: -1.0.m, y: 0.0.m), and: Point(x: +1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: -1.0.m), and: Point(x: 0.0.m, y: +1.0.m))!)! == (
                    1.0.m, 1.0.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!)! == (
                    13.0.m, 5.0.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!)! == (
                    2.6925824036.m, 2.06155281281.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!)! == (
                    8.0777472107017498.m, 2.06155281281.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 5.0.m, y: 11.0.m), and: Point(x: 4.0.m, y: 7.0.m))!)! == (
                    2.6925824036.m, 6.1846584384264878.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 5.0.m, y: 11.0.m), and: Point(x: 4.0.m, y: 7.0.m))!)! == (
                    8.0777472107017498.m, 6.1846584384264878.m
                ))
        XCTAssert(
            Line.argsForIntersection(
                Line(through: Point(x: -11.0.m, y: -2.0.m), and: Point(x: -6.0.m, y: -4.0.m))!,
                Line(through: Point(x: -5.0.m, y: -11.0.m), and: Point(x: -4.0.m, y: -7.0.m))!)!
                == (
                    8.0777472107017498.m, 6.1846584384264878.m
                ))
    }

    func testFindsNoArgsForIntersectionForParallelLines() {
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 3.0.m), and: Point(x: 1.0.m, y: 3.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 10.0.m, y: 7.0.m), and: Point(x: 11.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: -8.0.m, y: 0.0.m), and: Point(x: -8.0.m, y: 1.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 22.0.m, y: 0.0.m), and: Point(x: 22.0.m, y: 1.0.m))!,
                Line(through: Point(x: 19.0.m, y: 10.0.m), and: Point(x: 19.0.m, y: 11.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: -5.0.m, y: -7.0.m), and: Point(x: +23.0.m, y: -7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: -5.0.m, y: -7.0.m), and: Point(x: +23.0.m, y: -7.0.m))!,
                Line(through: Point(x: +5.0.m, y: +7.0.m), and: Point(x: -23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: -8.0.m, y: +2.0.m), and: Point(x: -8.0.m, y: +9.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: -8.0.m, y: +2.0.m), and: Point(x: -8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: -2.0.m), and: Point(x: +8.0.m, y: -9.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 1.0.m, y: 7.0.m), and: Point(x: 6.0.m, y: 5.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 5.0.m), and: Point(x: 6.0.m, y: 3.0.m))!,
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 2.0.m, y: 3.0.m), and: Point(x: 3.0.m, y: 7.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 7.0.m, y: 15.0.m), and: Point(x: 5.0.m, y: 7.0.m))!))
    }

    func testFindsNoArgsIntersectionForCoincidentLines() {
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 1.0.m, y: 0.0.m))!,
                Line(through: Point(x: 10.0.m, y: 0.0.m), and: Point(x: 11.0.m, y: 0.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 0.0.m, y: 0.0.m), and: Point(x: 0.0.m, y: 1.0.m))!,
                Line(through: Point(x: 0.0.m, y: 10.0.m), and: Point(x: 0.0.m, y: 11.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: -5.0.m, y: +7.0.m), and: Point(x: +23.0.m, y: +7.0.m))!,
                Line(through: Point(x: +5.0.m, y: +7.0.m), and: Point(x: -23.0.m, y: +7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: +8.0.m, y: +2.0.m), and: Point(x: +8.0.m, y: +9.0.m))!,
                Line(through: Point(x: +8.0.m, y: -2.0.m), and: Point(x: +8.0.m, y: -9.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 1.0.m, y: 6.0.m), and: Point(x: 6.0.m, y: 4.0.m))!,
                Line(through: Point(x: 11.0.m, y: 2.0.m), and: Point(x: 6.0.m, y: 4.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
        XCTAssertNil(
            Line.argsForIntersection(
                Line(through: Point(x: 3.0.m, y: 3.0.m), and: Point(x: 4.0.m, y: 7.0.m))!,
                Line(through: Point(x: 6.0.m, y: 15.0.m), and: Point(x: 4.0.m, y: 7.0.m))!))
    }

    func testFindsArgForIntersection() {
        let line1 = Line(
            through: Point(
                x: 542.52034735978793.m,
                y: 2573.6517612670732.m),
            and: Point(
                x: 594.81241698580266.m,
                y: 3038.7563078563485.m))!
        let line2 = Line(
            through: Point(
                x: -91.981378797517948.m,
                y: 1879.8347891148856.m),
            and: Point(
                x: 1121.4367902736726.m,
                y: 1879.8347891148856.m))!
        let p = Line.intersection(line1, line2)!
        XCTAssertEqual(line1.arg(for: p), -698.18836091037736.m)
        XCTAssertEqual(line2.arg(for: p), 556.49533881603941.m)
    }

}
