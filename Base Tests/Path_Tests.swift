//
//  Path_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 2/11/24.
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

final class FinitePath_Tests: XCTestCase {

    func testDeterminesLinearPathSegmentsInRect() {
        let path = LinearPath(
            start: Point(x: -17.0.m, y: 72.0.m),
            end: Point(x: 132.0.m, y: -9.0.m))!
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -10.0.m,
                    y: -10.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 62.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [0.0.m...11.382122950061735.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 55.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [0.0.m...11.382122950061735.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -7.0.m,
                    y: 62.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [11.382122950061735.m...20.937485426657219.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -7.0.m,
                    y: 42.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [20.937485426657219.m...34.146368850185205.m])
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 42.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: 102.0.m,
                    y: -19.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [148.65614652926419.m...158.21150900585812.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: 122.0.m,
                    y: -19.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [158.21150900585812.m...path.length])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: 122.0.m,
                    y: -12.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [158.21150900585812.m...path.length])
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: 122.0.m,
                    y: 1.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: -19.0.m,
                    width: 169.m,
                    height: 101.0.m)
            ), [0.0.m...path.length])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -17.0.m,
                    y: -9.0.m,
                    width: 149.m,
                    height: 81.0.m)
            ), [0.0.m...path.length])

        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: -19.0.m,
                    width: 9.0.m,
                    height: 101.0.m)
            ).isEmpty)
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: 133.0.m,
                    y: -19.0.m,
                    width: 9.0.m,
                    height: 101.0.m)
            ).isEmpty)
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: -19.0.m,
                    width: 169.0.m,
                    height: 9.0.m)
            ).isEmpty)
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 73.0.m,
                    width: 169.0.m,
                    height: 9.0.m)
            ).isEmpty)
    }

    func testDeterminesHorizontalLinearPathSegmentsInRect() {
        let pathA = LinearPath(
            start: Point(x: -17.0.m, y: 72.0.m),
            end: Point(x: 132.0.m, y: 72.0.m))!

        XCTAssert(
            pathA.segments(
                inRect: Rect(
                    x: -10.0.m,
                    y: -10.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 62.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [0.0.m...10.0.m])
        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: -12.0.m,
                    y: 59.0.m,
                    width: 23.0.m,
                    height: 37.0.m)
            ), [5.0.m...28.0.m])
        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: 120.0.m,
                    y: 70.5.m,
                    width: 39.0.m,
                    height: 3.0.m)
            ), [137.0.m...149.0.m])

        let pathB = LinearPath(
            start: Point(x: 132.0.m, y: 72.0.m),
            end: Point(x: -17.0.m, y: 72.0.m))!

        XCTAssert(
            pathB.segments(
                inRect: Rect(
                    x: -10.0.m,
                    y: -10.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: -27.0.m,
                    y: 62.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [139.0.m...149.0.m])
        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: -12.0.m,
                    y: 59.0.m,
                    width: 23.0.m,
                    height: 37.0.m)
            ), [121.0.m...144.m])
        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: 120.0.m,
                    y: 70.5.m,
                    width: 39.0.m,
                    height: 3.0.m)
            ), [0.0.m...12.0.m])
    }

    func testDeterminesVerticalLinearPathSegmentsInRect() {
        let pathA = LinearPath(
            start: Point(x: 72.0.m, y: -17.0.m),
            end: Point(x: 72.0.m, y: 132.0.m))!

        XCTAssert(
            pathA.segments(
                inRect: Rect(
                    x: -10.0.m,
                    y: -10.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: 62.0.m,
                    y: -27.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [0.0.m...10.0.m])
        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: 59.0.m,
                    y: -12.0.m,
                    width: 37.0.m,
                    height: 23.0.m)
            ), [5.0.m...28.0.m])
        XCTAssertEqual(
            pathA.segments(
                inRect: Rect(
                    x: 70.5.m,
                    y: 120.0.m,
                    width: 3.0.m,
                    height: 39.0.m)
            ), [137.0.m...149.0.m])

        let pathB = LinearPath(
            start: Point(x: 72.0.m, y: 132.0.m),
            end: Point(x: 72.0.m, y: -17.0.m))!

        XCTAssert(
            pathB.segments(
                inRect: Rect(
                    x: -10.0.m,
                    y: -10.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: 62.0.m,
                    y: -27.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ), [139.0.m...149.0.m])
        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: 59.0.m,
                    y: -12.0.m,
                    width: 37.0.m,
                    height: 23.0.m)
            ), [121.0.m...144.m])
        XCTAssertEqual(
            pathB.segments(
                inRect: Rect(
                    x: 70.5.m,
                    y: 120.0.m,
                    width: 3.0.m,
                    height: 39.0.m)
            ), [0.0.m...12.0.m])
    }

    func testDeterminesCircularPathSegmentsInRect() {
        let path = CircularPath(
            center: Point(x: 12.0.m, y: 34.0.m),
            radius: 90.0.m,
            startAngle: CircleAngle(-135.0.deg),
            deltaAngle: 120.0.deg)!
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -110.0.m,
                    y: -80.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: 2.0.m,
                    y: 24.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)
        XCTAssert(
            path.segments(
                inRect: Rect(
                    x: -88.0.m,
                    y: 24.0.m,
                    width: 20.0.m,
                    height: 20.0.m)
            ).isEmpty)

        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -120.0.m,
                    y: -90.0.m,
                    width: 250.0.m,
                    height: 350.0.m)),
            [0.0.m...path.length])

        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -62.0.m,
                    y: -40.0.m,
                    width: 20.0.m,
                    height: 80.0.m)),
            [0.0.m...12.770734914374762.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: 80.0.m,
                    y: -40.0.m,
                    width: 40.0.m,
                    height: 80.0.m)),
            [147.77099420040881.m...path.length])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -62.0.m,
                    y: -60.0.m,
                    width: 168.0.m,
                    height: 20.0.m)),
            [16.191563413629545.m...125.18010599791113.m])
        XCTAssertEqual(
            path.segments(
                inRect: Rect(
                    x: -62.0.m,
                    y: -40.0.m,
                    width: 168.0.m,
                    height: 80.0.m)),
            [0.0.m...16.191563413629545.m, 125.18010599791113.m...path.length])
    }

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

    func testDeterminesSubPathsOfLinearPath() {
        let originalPath = LinearPath(
            start: Point(x: 1.0.m, y: 1.0.m), end: Point(x: 51.0.m, y: 1.0.m))!

        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 15.0.m),
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m),
                    end: Point(x: 16.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            originalPath.subPath(from: 15.0.m, to: 35.0.m),
            .linear(
                LinearPath(
                    start: Point(x: 16.0.m, y: 1.0.m),
                    end: Point(x: 36.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            originalPath.subPath(from: 35.0.m, to: 50.0.m),
            .linear(
                LinearPath(
                    start: Point(x: 36.0.m, y: 1.0.m),
                    end: Point(x: 51.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 50.0.m),
            .linear(originalPath))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 20.0.m))
        XCTAssertNil(originalPath.subPath(from: 5.0.m, to: 60.0.m))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 60.0.m))
        XCTAssertNil(originalPath.subPath(from: 35.0.m, to: 15.0.m))
    }

    func testDeterminesSubPathsOfCircularPath() {
        let originalPath = CircularPath(
            center: Point(x: 12.3.m, y: 45.6.m),
            radius: 98.7.m,
            startAngle: CircleAngle(120.0.deg),
            endAngle: CircleAngle(230.0.deg),
            direction: .positive)!

        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 98.7.m * 30.0.deg),
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(120.0.deg),
                    endAngle: CircleAngle(150.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            originalPath.subPath(
                from: 98.7.m * 30.0.deg,
                to: 98.7.m * 70.0.deg),
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(150.0.deg),
                    endAngle: CircleAngle(190.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            originalPath.subPath(
                from: 98.7.m * 70.0.deg,
                to: 98.7.m * 110.0.deg),
            .circular(
                CircularPath(
                    center: Point(x: 12.3.m, y: 45.6.m),
                    radius: 98.7.m,
                    startAngle: CircleAngle(190.0.deg),
                    endAngle: CircleAngle(230.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 98.7.m * 110.0.deg),
            .circular(originalPath))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 20.0.m))
        XCTAssertNil(originalPath.subPath(from: 5.0.m, to: 98.7.m * 120.0.deg))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 98.7.m * 120.0.deg))
        XCTAssertNil(originalPath.subPath(from: 98.7.m * 70.0.deg, to: 98.7.m * 30.0.deg))
    }

    func testDeterminesSubPathsOfCompoundPath() {
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

        XCTAssertEqual(
            originalPath.subPath(
                from: 0.0.m,
                to: 40.0.m),
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m),
                    end: Point(x: 41.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            originalPath.subPath(
                from: 40.0.m,
                to: 50.0.m + 100.0.m * 30.0.deg),
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
            originalPath.subPath(
                from: 50.0.m + 100.0.m * 30.0.deg,
                to: 50.0.m + 100.0.m * 60.0.deg),
            .circular(
                CircularPath(
                    center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(300.0.deg), endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 50.0.m + 100.0.m * 60.0.deg),
            .compound(originalPath))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 40.0.m))
        XCTAssertNil(originalPath.subPath(from: 5.0.m, to: 50.0.m + 100.0.m * 70.0.deg))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 50.0.m + 100.0.m * 30.0.deg))
        XCTAssertNil(originalPath.subPath(from: 50.0.m + 100.0.m * 30.0.deg, to: 40.0.m))
    }

    func testDeterminesSubPathsOfSomeFinitePath() {
        let originalPath = SomeFinitePath.compound(
            CompoundPath(components: [
                .linear(
                    LinearPath(
                        start: Point(x: 1.0.m, y: 1.0.m), end: Point(x: 51.0.m, y: 1.0.m))!),
                .circular(
                    CircularPath(
                        center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(270.0.deg), endAngle: CircleAngle(330.0.deg),
                        direction: .positive)!),
            ])!)

        XCTAssertEqual(
            originalPath.subPath(
                from: 0.0.m,
                to: 40.0.m),
            .linear(
                LinearPath(
                    start: Point(x: 1.0.m, y: 1.0.m),
                    end: Point(x: 41.0.m, y: 1.0.m))!))
        XCTAssertEqual(
            originalPath.subPath(
                from: 40.0.m,
                to: 50.0.m + 100.0.m * 30.0.deg),
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
            originalPath.subPath(
                from: 50.0.m + 100.0.m * 30.0.deg,
                to: 50.0.m + 100.0.m * 60.0.deg),
            .circular(
                CircularPath(
                    center: Point(x: 51.0.m, y: 101.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(300.0.deg), endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!))
        XCTAssertEqual(
            originalPath.subPath(from: 0.0.m, to: 50.0.m + 100.0.m * 60.0.deg),
            originalPath)
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 40.0.m))
        XCTAssertNil(originalPath.subPath(from: 5.0.m, to: 50.0.m + 100.0.m * 70.0.deg))
        XCTAssertNil(originalPath.subPath(from: -5.0.m, to: 50.0.m + 100.0.m * 30.0.deg))
        XCTAssertNil(originalPath.subPath(from: 50.0.m + 100.0.m * 30.0.deg, to: 40.0.m))
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
