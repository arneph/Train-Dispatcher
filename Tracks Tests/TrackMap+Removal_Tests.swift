//
//  TrackMap+Removal_Tests.swift
//  Tracks Tests
//
//  Created by Arne Philipeit on 3/31/24.
//

import Base
import XCTest

@testable import Tracks

final class TrackMap_Remove_Tests: XCTestCase {

    func testRemovesTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)

        let _ = map.remove(oldTrack: oldTrack)

        XCTAssert(map.tracks.isEmpty)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack, map),
                .removedTrack(oldTrack, map),
            ])
        XCTAssertEqual(
            oldTrackObserver.calls,
            [
                .removed(oldTrack)
            ])
    }

    func testRemovesEntireTrackSection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: oldTrack, from: 0.0.m, to: 68.0.m)

        XCTAssertNil(newTrack1)
        XCTAssertNil(newTrack2)
        XCTAssert(map.tracks.isEmpty)
        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack, map),
                .removedTrack(oldTrack, map),
            ])
        XCTAssertEqual(
            oldTrackObserver.calls,
            [
                .removed(oldTrack)
            ])
    }

    func testRemovesTrackAndStartConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack1, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let (oldTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: 134.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(270.0.deg),
                    endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!),
            startConnection: .toNewConnection(oldTrack1, 23.0.m),
            endConnection: .none)
        let oldTrack2Observer = TestTrackObserver(for: oldTrack2)
        let oldTrack3 = map.tracks[0]
        let oldTrack3Observer = TestTrackObserver(for: oldTrack3)
        let oldTrack4 = map.tracks[1]
        let oldTrack4Observer = TestTrackObserver(for: oldTrack4)
        let oldConnection = map.connections[0]
        let oldConnectionObserver = TestTrackConnectionObserver(for: oldConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack1, map),
                .replacedTrack(oldTrack1, [oldTrack3, oldTrack4], map),
                .addedConnection(oldConnection, map),
                .addedTrack(oldTrack2, map),
            ])
        mapObserver.calls = []

        let _ = map.remove(oldTrack: oldTrack2)

        XCTAssertEqual(map.tracks.count, 1)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack1 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack2 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack3 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack4 }))
        let newTrack = map.tracks[0]
        let newTrackObserver = TestTrackObserver(for: newTrack)

        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .replacedTrack(oldTrack4, [newTrack], map),
                .replacedTrack(oldTrack3, [newTrack], map),
                .removedConnection(oldConnection, map),
                .removedTrack(oldTrack2, map),
            ])
        XCTAssertEqual(
            oldTrack2Observer.calls,
            [
                .removed(oldTrack2)
            ])
        XCTAssertEqual(
            oldTrack3Observer.calls,
            [
                .replaced(
                    oldTrack3, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 23.0.m {
                            (newTrack, 68.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssertEqual(
            oldTrack4Observer.calls,
            [
                .replaced(
                    oldTrack4, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 45.0.m {
                            (newTrack, 45.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssertEqual(
            oldConnectionObserver.calls,
            [
                .removedTrack(oldTrack2, oldConnection),
                .removed(oldConnection),
            ])
    }

    func testRemovesTrackButNotStartConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack1, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let (oldTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: 134.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(270.0.deg),
                    endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!),
            startConnection: .toNewConnection(oldTrack1, 23.0.m),
            endConnection: .none)
        let oldTrack2Observer = TestTrackObserver(for: oldTrack2)
        let track3 = map.tracks[0]
        let track3Observer = TestTrackObserver(for: track3)
        let track4 = map.tracks[1]
        let track4Observer = TestTrackObserver(for: track4)
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        let (track5, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: -66.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(90.0.deg),
                    endAngle: CircleAngle(120.0.deg),
                    direction: .positive)!),
            startConnection: .toExistingConnection(connection),
            endConnection: .none)
        let track5Observer = TestTrackObserver(for: track5)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack1, map),
                .replacedTrack(oldTrack1, [track3, track4], map),
                .addedConnection(connection, map),
                .addedTrack(oldTrack2, map),
                .connectionChanged(connection, map),
                .addedTrack(track5, map),
            ])
        mapObserver.calls = []
        XCTAssertEqual(
            connectionObserver.calls,
            [
                .addedTrack(track5, connection, .b)
            ])
        connectionObserver.calls = []

        let _ = map.remove(oldTrack: oldTrack2)

        XCTAssertEqual(map.tracks.count, 3)
        XCTAssertFalse(map.tracks.contains { $0 === oldTrack1 })
        XCTAssertFalse(map.tracks.contains { $0 === oldTrack2 })
        XCTAssert(map.tracks.contains { $0 === track3 })
        XCTAssert(map.tracks.contains { $0 === track4 })
        XCTAssert(map.tracks.contains { $0 === track5 })

        XCTAssertEqual(map.connections.count, 1)
        XCTAssert(map.connections.contains { $0 === connection })
        XCTAssertEqual(
            mapObserver.calls,
            [
                .removedTrack(oldTrack2, map)
            ])
        XCTAssertEqual(
            oldTrack2Observer.calls,
            [
                .removed(oldTrack2)
            ])
        XCTAssert(track3Observer.calls.isEmpty)
        XCTAssert(track4Observer.calls.isEmpty)
        XCTAssert(track5Observer.calls.isEmpty)
        XCTAssertEqual(
            connectionObserver.calls,
            [
                .removedTrack(oldTrack2, connection)
            ])
    }

    func testRemovesTrackAndEndConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack1, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let (oldTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: 134.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(330.0.deg),
                    endAngle: CircleAngle(270.0.deg),
                    direction: .negative)!),
            startConnection: .none,
            endConnection: .toNewConnection(oldTrack1, 23.0.m))
        let oldTrack2Observer = TestTrackObserver(for: oldTrack2)
        let oldTrack3 = map.tracks[0]
        let oldTrack3Observer = TestTrackObserver(for: oldTrack3)
        let oldTrack4 = map.tracks[1]
        let oldTrack4Observer = TestTrackObserver(for: oldTrack4)
        let oldConnection = map.connections[0]
        let oldConnectionObserver = TestTrackConnectionObserver(for: oldConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack1, map),
                .replacedTrack(oldTrack1, [oldTrack3, oldTrack4], map),
                .addedConnection(oldConnection, map),
                .addedTrack(oldTrack2, map),
            ])
        mapObserver.calls = []

        let _ = map.remove(oldTrack: oldTrack2)

        XCTAssertEqual(map.tracks.count, 1)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack1 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack2 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack3 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack4 }))
        let newTrack = map.tracks[0]
        let newTrackObserver = TestTrackObserver(for: newTrack)

        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .replacedTrack(oldTrack4, [newTrack], map),
                .replacedTrack(oldTrack3, [newTrack], map),
                .removedConnection(oldConnection, map),
                .removedTrack(oldTrack2, map),
            ])
        XCTAssertEqual(
            oldTrack2Observer.calls,
            [
                .removed(oldTrack2)
            ])
        XCTAssertEqual(
            oldTrack3Observer.calls,
            [
                .replaced(
                    oldTrack3, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 23.0.m {
                            (newTrack, 68.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssertEqual(
            oldTrack4Observer.calls,
            [
                .replaced(
                    oldTrack4, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 45.0.m {
                            (newTrack, 45.0.m  - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssertEqual(
            oldConnectionObserver.calls,
            [
                .removedTrack(oldTrack2, oldConnection),
                .removed(oldConnection),
            ])
    }

    func testRemovesStartSectionForTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: track,
            from: 0.0.m,
            to: 30.0.m)
        XCTAssertNil(newTrack1)
        XCTAssert(newTrack2 === track)

        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.contains { $0 === track })
        XCTAssert(map.connections.isEmpty)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(track, map),
                .trackChanged(track, map),
            ])
        XCTAssertEqual(
            trackObserver.calls,
            [
                .pathChanged(
                    track,
                    { x in
                        x - 30.0.m
                    })
            ])
    }

    func testRemovesMiddleSectionForTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: oldTrack,
            from: 10.0.m,
            to: 30.0.m)
        XCTAssertNotNil(newTrack1)
        XCTAssertNotNil(newTrack2)
        guard let newTrack1 = newTrack1, let newTrack2 = newTrack2 else { return }
        let newTrack1Observer = TestTrackObserver(for: newTrack1)
        let newTrack2Observer = TestTrackObserver(for: newTrack2)

        XCTAssertEqual(map.tracks.count, 2)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack }))
        XCTAssert(map.tracks.contains { $0 === newTrack1 })
        XCTAssert(map.tracks.contains { $0 === newTrack2 })
        XCTAssert(map.connections.isEmpty)
        XCTAssertNil(newTrack1.startConnection)
        XCTAssertNil(newTrack1.endConnection)
        XCTAssertNil(newTrack2.startConnection)
        XCTAssertNil(newTrack2.endConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack, map),
                .replacedTrack(oldTrack, [newTrack1, newTrack2], map),
            ])
        XCTAssertEqual(
            oldTrackObserver.calls,
            [
                .replaced(
                    oldTrack, [newTrack1, newTrack2],
                    { x in
                        if 0.0.m <= x && x <= 10.0.m {
                            (newTrack1, x)
                        } else if 30.0.m <= x && x <= 68.0.m {
                            (newTrack2, x - 30.0.m)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssert(newTrack1Observer.calls.isEmpty)
        XCTAssert(newTrack2Observer.calls.isEmpty)
    }

    func testRemovesMiddleSectionForTrackWithConnections() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let oldTrackObserver = TestTrackObserver(for: oldTrack)
        let (connectedTrack1, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: -23.0.m, y: 134.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(-90.0.deg), endAngle: CircleAngle(-60.0.deg),
                    direction: .positive)!),
            startConnection: .toNewConnection(oldTrack, 0.0.m), endConnection: .none)
        let connectedTrack1Observer = TestTrackObserver(for: connectedTrack1)
        let (connectedTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 45.0.m, y: -66.0.m), radius: 100.0.m,
                    startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(120.0.deg),
                    direction: .positive)!),
            startConnection: .toNewConnection(oldTrack, 68.0.m), endConnection: .none)
        let connectedTrack2Observer = TestTrackObserver(for: connectedTrack2)
        let connection1 = map.connections[0]
        let connection1Observer = TestTrackConnectionObserver(for: connection1)
        let connection2 = map.connections[1]
        let connection2Observer = TestTrackConnectionObserver(for: connection2)

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: oldTrack,
            from: 10.0.m,
            to: 30.0.m)
        XCTAssertNotNil(newTrack1)
        XCTAssertNotNil(newTrack2)
        guard let newTrack1 = newTrack1, let newTrack2 = newTrack2 else { return }
        let newTrack1Observer = TestTrackObserver(for: newTrack1)
        let newTrack2Observer = TestTrackObserver(for: newTrack2)

        XCTAssertEqual(map.tracks.count, 4)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack }))
        XCTAssert(map.tracks.contains { $0 === connectedTrack1 })
        XCTAssert(map.tracks.contains { $0 === connectedTrack2 })
        XCTAssert(map.tracks.contains { $0 === newTrack1 })
        XCTAssert(map.tracks.contains { $0 === newTrack2 })
        XCTAssertEqual(map.connections.count, 2)
        XCTAssert(map.connections.contains { $0 === connection1 })
        XCTAssert(map.connections.contains { $0 === connection2 })
        XCTAssert(newTrack1.startConnection === connection1)
        XCTAssertNil(newTrack1.endConnection)
        XCTAssertNil(newTrack2.startConnection)
        XCTAssert(newTrack2.endConnection === connection2)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack, map),
                .addedConnection(connection1, map),
                .addedTrack(connectedTrack1, map),
                .addedConnection(connection2, map),
                .addedTrack(connectedTrack2, map),
                .replacedTrack(oldTrack, [newTrack1, newTrack2], map),
            ])
        XCTAssertEqual(
            oldTrackObserver.calls,
            [
                .startConnectionChanged(oldTrack, nil),
                .endConnectionChanged(oldTrack, nil),
                .replaced(
                    oldTrack, [newTrack1, newTrack2],
                    { x in
                        if 0.0.m <= x && x <= 10.0.m {
                            (newTrack1, x)
                        } else if 30.0.m <= x && x <= 68.0.m {
                            (newTrack2, x - 30.0.m)
                        } else {
                            nil
                        }
                    }),
            ])
        XCTAssert(newTrack1Observer.calls.isEmpty)
        XCTAssert(newTrack2Observer.calls.isEmpty)
        XCTAssert(connectedTrack1Observer.calls.isEmpty)
        XCTAssert(connectedTrack2Observer.calls.isEmpty)
        XCTAssertEqual(
            connection1Observer.calls,
            [
                .replacedTrack(oldTrack, newTrack1, connection1, .a)
            ])
        XCTAssertEqual(
            connection2Observer.calls,
            [
                .replacedTrack(oldTrack, newTrack2, connection2, .b)
            ])
    }

    func testRemovesEndSectionForTrack() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let trackObserver = TestTrackObserver(for: track)

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: track,
            from: 30.0.m,
            to: 68.0.m)
        XCTAssert(newTrack1 === track)
        XCTAssertNil(newTrack2)

        XCTAssertEqual(map.tracks.count, 1)
        XCTAssert(map.tracks.contains { $0 === track })
        XCTAssert(map.connections.isEmpty)
        XCTAssertNil(track.startConnection)
        XCTAssertNil(track.endConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(track, map),
                .trackChanged(track, map),
            ])
        XCTAssertEqual(
            trackObserver.calls,
            [
                .pathChanged(
                    track,
                    { x in
                        x
                    })
            ])
    }

    func testRemovesStartSectionAndConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack1, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let (oldTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: 134.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(270.0.deg),
                    endAngle: CircleAngle(330.0.deg),
                    direction: .positive)!),
            startConnection: .toNewConnection(oldTrack1, 23.0.m),
            endConnection: .none)
        let oldTrack2Observer = TestTrackObserver(for: oldTrack2)
        let oldTrack3 = map.tracks[0]
        let oldTrack3Observer = TestTrackObserver(for: oldTrack3)
        let oldTrack4 = map.tracks[1]
        let oldTrack4Observer = TestTrackObserver(for: oldTrack4)
        let oldConnection = map.connections[0]
        let oldConnectionObserver = TestTrackConnectionObserver(for: oldConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack1, map),
                .replacedTrack(oldTrack1, [oldTrack3, oldTrack4], map),
                .addedConnection(oldConnection, map),
                .addedTrack(oldTrack2, map),
            ])
        mapObserver.calls = []

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: oldTrack2, from: 0.0.m, to: 10.0.m)

        XCTAssertNil(newTrack1)
        XCTAssert(newTrack2 === oldTrack2)
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack1 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack3 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack4 }))
        XCTAssert(map.tracks[0] === oldTrack2)
        let newTrack = map.tracks[1]
        let newTrackObserver = TestTrackObserver(for: newTrack)

        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .replacedTrack(oldTrack4, [newTrack], map),
                .replacedTrack(oldTrack3, [newTrack], map),
                .removedConnection(oldConnection, map),
                .trackChanged(oldTrack2, map),
            ])
        XCTAssertEqual(
            oldTrack2Observer.calls,
            [
                .startConnectionChanged(oldTrack2, oldConnection),
                .pathChanged(
                    oldTrack2,
                    { x in
                        x - 10.0.m
                    }),
            ])
        XCTAssertEqual(
            oldTrack3Observer.calls,
            [
                .replaced(
                    oldTrack3, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 23.0.m {
                            (newTrack, 68.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssertEqual(
            oldTrack4Observer.calls,
            [
                .replaced(
                    oldTrack4, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 45.0.m {
                            (newTrack, 45.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssertEqual(
            oldConnectionObserver.calls,
            [
                .removedTrack(oldTrack2, oldConnection),
                .removed(oldConnection),
            ])
    }

    func testRemovesEndSectionAndConnection() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (oldTrack1, _) = map.addTrack(
            withPath: .linear(
                LinearPath(start: Point(x: -23.0.m, y: 34.0.m), end: Point(x: 45.0.m, y: 34.0.m))!),
            startConnection: .none, endConnection: .none)
        let (oldTrack2, _) = map.addTrack(
            withPath: .circular(
                CircularPath(
                    center: Point(x: 0.0.m, y: 134.0.m),
                    radius: 100.0.m, startAngle: CircleAngle(330.0.deg),
                    endAngle: CircleAngle(270.0.deg),
                    direction: .negative)!),
            startConnection: .none,
            endConnection: .toNewConnection(oldTrack1, 23.0.m))
        let oldTrack2Observer = TestTrackObserver(for: oldTrack2)
        let oldTrack3 = map.tracks[0]
        let oldTrack3Observer = TestTrackObserver(for: oldTrack3)
        let oldTrack4 = map.tracks[1]
        let oldTrack4Observer = TestTrackObserver(for: oldTrack4)
        let oldConnection = map.connections[0]
        let oldConnectionObserver = TestTrackConnectionObserver(for: oldConnection)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .addedTrack(oldTrack1, map),
                .replacedTrack(oldTrack1, [oldTrack3, oldTrack4], map),
                .addedConnection(oldConnection, map),
                .addedTrack(oldTrack2, map),
            ])
        mapObserver.calls = []

        let (newTrack1, newTrack2, _) = map.removeSection(
            ofTrack: oldTrack2, from: 10.0.m, to: oldTrack2.path.length)

        XCTAssert(newTrack1 === oldTrack2)
        XCTAssertNil(newTrack2)
        XCTAssertEqual(map.tracks.count, 2)
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack1 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack3 }))
        XCTAssertFalse(map.tracks.contains(where: { $0 === oldTrack4 }))
        XCTAssert(map.tracks[0] === oldTrack2)
        let newTrack = map.tracks[1]
        let newTrackObserver = TestTrackObserver(for: newTrack)

        XCTAssert(map.connections.isEmpty)
        XCTAssertEqual(
            mapObserver.calls,
            [
                .replacedTrack(oldTrack4, [newTrack], map),
                .replacedTrack(oldTrack3, [newTrack], map),
                .removedConnection(oldConnection, map),
                .trackChanged(oldTrack2, map),
            ])
        XCTAssertEqual(
            oldTrack2Observer.calls,
            [
                .endConnectionChanged(oldTrack2, oldConnection),
                .pathChanged(
                    oldTrack2,
                    { x in
                        x
                    }),
            ])
        XCTAssertEqual(
            oldTrack3Observer.calls,
            [
                .replaced(
                    oldTrack3, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 23.0.m {
                            (newTrack, 68.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssertEqual(
            oldTrack4Observer.calls,
            [
                .replaced(
                    oldTrack4, [newTrack],
                    { x in
                        if 0.0.m <= x && x <= 45.0.m {
                            (newTrack, 45.0.m - x)
                        } else {
                            nil
                        }
                    })
            ])
        XCTAssert(newTrackObserver.calls.isEmpty)
        XCTAssertEqual(
            oldConnectionObserver.calls,
            [
                .removedTrack(oldTrack2, oldConnection),
                .removed(oldConnection),
            ])
    }

}
