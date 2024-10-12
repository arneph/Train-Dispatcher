//
//  TrackConnection+Switches_Test.swift
//  Tracks Tests
//
//  Created by Arne Philipeit on 10/12/24.
//

import Base
import XCTest

@testable import Tracks

final class TrackConnection_Switches_Tests: XCTestCase {
    
    func testSwitchesDirectionAState() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 0.0.m), end: Point(x: 10.0.m, y: 100.0.m))!),
            startConnection: .none, endConnection: .none)
        let (track2, _) = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(180.0.deg), endAngle: CircleAngle(90.0.deg),
                        direction: .negative)!), startConnection: .toNewConnection(track1, 0.0.m),
            endConnection: .none)
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionA(to: track2)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.8)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(1.5.s)
        XCTAssertEqual(connection.directionAState, .fixed(track2))
        XCTAssertEqual(connectionObserver.calls, [
            .stoppedChangingState(connection, .a)
        ])
    }
    
    func testSkipsDirectionAStateChange() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 0.0.m), end: Point(x: 10.0.m, y: 100.0.m))!),
            startConnection: .none, endConnection: .none)
        let _ = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(180.0.deg), endAngle: CircleAngle(90.0.deg),
                        direction: .negative)!), startConnection: .toNewConnection(track1, 0.0.m),
            endConnection: .none)
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionA(to: track1)
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
    }
    
    func testInterruptsDirectionAStateChange() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 0.0.m), end: Point(x: 10.0.m, y: 100.0.m))!),
            startConnection: .none, endConnection: .none)
        let (track2, _) = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(180.0.deg), endAngle: CircleAngle(90.0.deg),
                        direction: .negative)!), startConnection: .toNewConnection(track1, 0.0.m),
            endConnection: .none)
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionA(to: track2)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .a)
        ])
        connectionObserver.calls = []
        
        connection.switchDirectionA(to: track1)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track1, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionAState, .changing(TrackConnection.StateChange(previous: track1, next: track1, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .a)
        ])
        connectionObserver.calls = []
        
        map.tick(10.0.s)
        XCTAssertEqual(connection.directionAState, .fixed(track1))
        XCTAssertEqual(connectionObserver.calls, [
            .stoppedChangingState(connection, .a)
        ])
    }
    
    func testSwitchesDirectionBState() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let (track2, _) = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(track1, 100.0.m))
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionB(to: track2)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.8)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(1.5.s)
        XCTAssertEqual(connection.directionBState, .fixed(track2))
        XCTAssertEqual(connectionObserver.calls, [
            .stoppedChangingState(connection, .b)
        ])
    }
    
    func testSkipsDirectionBStateChange() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let _ = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(track1, 100.0.m))
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionB(to: track1)
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
    }
    
    func testInterruptsDirectionBStateChange() {
        let map = TrackMap()
        let mapObserver = TestTrackMapObserver(for: map)
        let (track1, _) = map.addTrack(
            withPath:
                .linear(
                    LinearPath(
                        start: Point(x: 10.0.m, y: 100.0.m), end: Point(x: 10.0.m, y: 0.0.m))!),
            startConnection: .none, endConnection: .none)
        let (track2, _) = map.addTrack(
            withPath:
                .circular(
                    CircularPath(
                        center: Point(x: 110.0.m, y: 0.0.m), radius: 100.0.m,
                        startAngle: CircleAngle(90.0.deg), endAngle: CircleAngle(180.0.deg),
                        direction: .positive)!), startConnection: .none,
            endConnection: .toNewConnection(track1, 100.0.m))
        mapObserver.calls = []
        let connection = map.connections[0]
        let connectionObserver = TestTrackConnectionObserver(for: connection)
        
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        map.tick(12.3.s)
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssert(connectionObserver.calls.isEmpty)
        
        connection.switchDirectionB(to: track2)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track2, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .b)
        ])
        connectionObserver.calls = []
        
        connection.switchDirectionB(to: track1)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track1, progress: 0.0)))
        XCTAssertEqual(connectionObserver.calls, [
            .startedChangingState(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(2.0.s)
        XCTAssertEqual(connection.directionBState, .changing(TrackConnection.StateChange(previous: track1, next: track1, progress: 0.4)))
        XCTAssertEqual(connectionObserver.calls, [
            .progressedStateChange(connection, .b)
        ])
        connectionObserver.calls = []
        
        map.tick(10.0.s)
        XCTAssertEqual(connection.directionBState, .fixed(track1))
        XCTAssertEqual(connectionObserver.calls, [
            .stoppedChangingState(connection, .b)
        ])
        connectionObserver.calls = []
    }
    
}
