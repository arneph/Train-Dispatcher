//
//  TrackPen_Tests.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 3/26/24.
//

import Base
import Tracks
import XCTest

@testable import Train_Dispatcher

final class TrackPen_Tests: XCTestCase {

    func testCreatesTrackForFreeformDrag() {
        let map = Map()
        let changeManager = ChangeManager()
        let penOwner = TestToolOwner(
            mapPointAtViewCenter: Point(x: 12.34.m, y: 56.78.m),
            mapScale: 3.45,
            map: map,
            changeManager: changeManager)
        let pen = TrackPen(owner: penOwner)

        pen.mouseDown(point: Point(x: 5.0.m, y: 15.0.m))
        XCTAssertEqual(penOwner.calls, [.stateChanged(pen)])
        penOwner.calls = []

        pen.mouseUp(point: Point(x: 35.0.m, y: 25.0.m))
        XCTAssertEqual(penOwner.calls, [.stateChanged(pen)])

        XCTAssertEqual(map.trackMap.tracks.count, 1)
        let track = map.trackMap.tracks[0]
        XCTAssert(track.startConnection === nil)
        XCTAssert(track.endConnection === nil)
        XCTAssertEqual(
            track.path,
            .linear(
                LinearPath(
                    start: Point(x: 5.0.m, y: 15.0.m),
                    end: Point(x: 35.0.m, y: 25.0.m))!))
        XCTAssert(changeManager.canUndo)
    }

}
