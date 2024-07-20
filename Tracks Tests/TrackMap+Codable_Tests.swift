//
//  TrackMap+Codable_Tests.swift
//  Tracks Tests
//
//  Created by Arne Philipeit on 3/31/24.
//

import Base
import XCTest

@testable import Tracks

func encodeAndDecode(_ original: TrackMap) throws -> TrackMap {
    let encoder = JSONEncoder()
    let encoded = try encoder.encode(original)
    let decoder = JSONDecoder()
    return try decoder.decode(TrackMap.self, from: encoded)
}

final class TrackMap_Codable_Tests: XCTestCase {

    func testEncodesAndDecodesEmptyTrackMap() throws {
        let original = TrackMap()
        let result = try encodeAndDecode(original)
        XCTAssert(result.tracks.isEmpty)
        XCTAssert(result.connections.isEmpty)
    }

    func testEncodesAndDecodesTrackMapWithSingleTrack() throws {
        let path: SomeFinitePath = .linear(
            LinearPath(start: Point(x: -5.0.m, y: 0.0.m), end: Point(x: +5.0.m, y: 0.0.m))!)
        let originalMap = TrackMap()
        let (originalTrack, _) = originalMap.addTrack(
            withPath: path, startConnection: .none, endConnection: .none)
        let originalTrackObserver = TestTrackObserver(for: originalTrack)

        let resultMap = try encodeAndDecode(originalMap)
        XCTAssertEqual(resultMap.tracks.count, 1)
        XCTAssert(resultMap.connections.isEmpty)

        let resultTrack = resultMap.tracks.first!
        XCTAssertEqual(resultTrack.path, path)
        XCTAssertEqual(resultTrack.leftRail, originalTrack.leftRail)
        XCTAssertEqual(resultTrack.rightRail, originalTrack.rightRail)
        XCTAssertNil(resultTrack.startConnection)
        XCTAssertNil(resultTrack.endConnection)

        XCTAssert(originalTrackObserver.calls.isEmpty)
    }

    func testEncodesAndDecodesTrackMapWithSingleConnection() throws {
        let originalMap = TrackMap()
        let (originalTrack1, _) = originalMap.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(originalTrack1, 100.0.m))
        let originalConnection = originalMap.connections[0]
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: -90.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-90.0.deg),
                        direction: .negative)!),
            startConnection: .toExistingConnection(originalConnection),
            endConnection: .none)

        let resultMap = try encodeAndDecode(originalMap)
        XCTAssertEqual(resultMap.tracks.count, 3)
        XCTAssertEqual(resultMap.connections.count, 1)

        let resultTrack1 = resultMap.tracks[0]
        let resultTrack2 = resultMap.tracks[1]
        let resultTrack3 = resultMap.tracks[2]
        let resultConnection = resultMap.connections[0]
        XCTAssertEqual(
            resultTrack1.path,
            .linear(
                LinearPath(start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!))
        XCTAssertNil(resultTrack1.startConnection)
        XCTAssert(resultTrack1.endConnection === resultConnection)
        XCTAssertEqual(
            resultTrack2.path,
            .circular(
                CircularPath(
                    center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                    direction: .positive)!))
        XCTAssertNil(resultTrack2.startConnection)
        XCTAssert(resultTrack2.endConnection === resultConnection)
        XCTAssertEqual(
            resultTrack3.path,
            .circular(
                CircularPath(
                    center: Point(x: -90.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-90.0.deg),
                    direction: .negative)!))
        XCTAssert(resultTrack3.startConnection === resultConnection)
        XCTAssertNil(resultTrack3.endConnection)
        XCTAssertEqual(resultConnection.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(resultConnection.directionA, CircleAngle(-90.0.deg))
        XCTAssertEqual(resultConnection.directionB, CircleAngle(+90.0.deg))
        XCTAssertEqual(resultConnection.directionATracks.count, 1)
        XCTAssertEqual(resultConnection.directionBTracks.count, 2)
        XCTAssert(resultConnection.directionATracks.contains { $0 === resultTrack3 })
        XCTAssert(resultConnection.directionBTracks.contains { $0 === resultTrack1 })
        XCTAssert(resultConnection.directionBTracks.contains { $0 === resultTrack2 })
    }

    func testEncodesAndDecodesTrackMapWithConnections() throws {
        let originalMap = TrackMap()
        let (originalTrack1, _) = originalMap.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(originalTrack1, 100.0.m))
        let originalConnection1 = originalMap.connections[0]
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: -90.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-90.0.deg),
                        direction: .negative)!),
            startConnection: .toExistingConnection(originalConnection1),
            endConnection: .none)

        let (originalTrack4, _) = originalMap.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 210.0.m, y: 100.0.m), end: Point(x: 210.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 310.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(originalTrack4, 100.0.m))
        let originalConnection2 = originalMap.connections[1]
        let _ = originalMap.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-180.0.deg),
                        direction: .negative)!),
            startConnection: .toExistingConnection(originalConnection2),
            endConnection: .toExistingConnection(originalConnection1))

        let resultMap = try encodeAndDecode(originalMap)
        XCTAssertEqual(resultMap.tracks.count, 6)
        XCTAssertEqual(resultMap.connections.count, 2)

        let resultTrack1 = resultMap.tracks[0]
        let resultTrack2 = resultMap.tracks[1]
        let resultTrack3 = resultMap.tracks[2]
        let resultTrack4 = resultMap.tracks[3]
        let resultTrack5 = resultMap.tracks[4]
        let resultTrack6 = resultMap.tracks[5]
        let resultConnection1 = resultMap.connections[0]
        let resultConnection2 = resultMap.connections[1]
        XCTAssertEqual(
            resultTrack1.path,
            .linear(
                LinearPath(start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!))
        XCTAssertNil(resultTrack1.startConnection)
        XCTAssert(resultTrack1.endConnection === resultConnection1)
        XCTAssertEqual(
            resultTrack2.path,
            .circular(
                CircularPath(
                    center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                    direction: .positive)!))
        XCTAssertNil(resultTrack2.startConnection)
        XCTAssert(resultTrack2.endConnection === resultConnection1)
        XCTAssertEqual(
            resultTrack3.path,
            .circular(
                CircularPath(
                    center: Point(x: -90.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-90.0.deg),
                    direction: .negative)!))
        XCTAssert(resultTrack3.startConnection === resultConnection1)
        XCTAssertNil(resultTrack3.endConnection)
        XCTAssertEqual(
            resultTrack4.path,
            .linear(
                LinearPath(start: Point(x: 210.0.m, y: 100.0.m), end: Point(x: 210.0.m, y: 0.0.m))!)
        )
        XCTAssertNil(resultTrack4.startConnection)
        XCTAssert(resultTrack4.endConnection === resultConnection2)
        XCTAssertEqual(
            resultTrack5.path,
            .circular(
                CircularPath(
                    center: Point(x: 310.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                    direction: .positive)!))
        XCTAssertNil(resultTrack5.startConnection)
        XCTAssert(resultTrack5.endConnection === resultConnection2)
        XCTAssertEqual(
            resultTrack6.path,
            .circular(
                CircularPath(
                    center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(0.0.deg), endAngle: CircleAngle(-180.0.deg),
                    direction: .negative)!))
        XCTAssert(resultTrack6.startConnection === resultConnection2)
        XCTAssert(resultTrack6.endConnection === resultConnection1)
        XCTAssertEqual(resultConnection1.point, Point(x: 10.0.m, y: 0.0.m))
        XCTAssertEqual(resultConnection1.directionA, CircleAngle(-90.0.deg))
        XCTAssertEqual(resultConnection1.directionB, CircleAngle(+90.0.deg))
        XCTAssertEqual(resultConnection1.directionATracks.count, 2)
        XCTAssertEqual(resultConnection1.directionBTracks.count, 2)
        XCTAssert(resultConnection1.directionATracks.contains { $0 === resultTrack3 })
        XCTAssert(resultConnection1.directionATracks.contains { $0 === resultTrack6 })
        XCTAssert(resultConnection1.directionBTracks.contains { $0 === resultTrack1 })
        XCTAssert(resultConnection1.directionBTracks.contains { $0 === resultTrack2 })
        XCTAssertEqual(resultConnection2.point, Point(x: 210.0.m, y: 0.0.m))
        XCTAssertEqual(resultConnection2.directionA, CircleAngle(-90.0.deg))
        XCTAssertEqual(resultConnection2.directionB, CircleAngle(+90.0.deg))
        XCTAssertEqual(resultConnection2.directionATracks.count, 1)
        XCTAssertEqual(resultConnection2.directionBTracks.count, 2)
        XCTAssert(resultConnection2.directionATracks.contains { $0 === resultTrack6 })
        XCTAssert(resultConnection2.directionBTracks.contains { $0 === resultTrack4 })
        XCTAssert(resultConnection2.directionBTracks.contains { $0 === resultTrack5 })
    }

}
