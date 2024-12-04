//
//  TrackMapValidation.swift
//  Tracks Tests
//
//  Created by Arne Philipeit on 12/3/24.
//

import Foundation
import Tracks
import XCTest

func check(_ trackMap: TrackMap) {
    for track in trackMap.tracks {
        check(track: track, in: trackMap)
    }
    for connection in trackMap.connections {
        check(connection: connection, in: trackMap)
    }
}

fileprivate func check(track: Track, in trackMap: TrackMap) {
    if let startConnection = track.startConnection {
        XCTAssert(trackMap.connections.contains { $0 === startConnection })
        XCTAssertEqual(startConnection.point, track.path.start)
        if startConnection.directionA == track.path.startOrientation {
            XCTAssert(startConnection.directionATracks.contains { $0 === track })
        } else if startConnection.directionB == track.path.startOrientation {
            XCTAssert(startConnection.directionBTracks.contains { $0 === track })
        } else {
            XCTFail("Track and start TrackConnection are not alligned.")
        }
    }
    if let endConnection = track.endConnection {
        XCTAssert(trackMap.connections.contains { $0 === endConnection })
        XCTAssertEqual(endConnection.point, track.path.end)
        if endConnection.directionA == track.path.endOrientation {
            XCTAssert(endConnection.directionBTracks.contains { $0 === track })
        } else if endConnection.directionB == track.path.endOrientation {
            XCTAssert(endConnection.directionATracks.contains { $0 === track })
        } else {
            XCTFail("Track and end TrackConnection are not alligned.")
        }
    }
}

fileprivate func check(connection: TrackConnection, in trackMap: TrackMap) {
    XCTAssert(connection.directionATracks.count > 1 || connection.directionBTracks.count > 1)
    for directionATrack in connection.directionATracks {
        XCTAssert(trackMap.tracks.contains { $0 === directionATrack })
    }
    for directionBTrack in connection.directionBTracks {
        XCTAssert(trackMap.tracks.contains { $0 === directionBTrack })
    }
    if let directionAState = connection.directionAState {
        switch directionAState {
        case .fixed(let track):
            XCTAssert(connection.directionATracks.contains { $0 === track })
        case .changing(let change):
            XCTAssert(change.previous !== change.next)
            XCTAssert((0.0...1.0).contains(change.progress))
            XCTAssert(connection.directionATracks.contains { $0 === change.previous })
            XCTAssert(connection.directionATracks.contains { $0 === change.next })
        }
    } else {
        XCTAssert(connection.directionATracks.isEmpty)
    }
    if let directionBState = connection.directionBState {
        switch directionBState {
        case .fixed(let track):
            XCTAssert(connection.directionBTracks.contains { $0 === track })
        case .changing(let change):
            XCTAssert(change.previous !== change.next)
            XCTAssert((0.0...1.0).contains(change.progress))
            XCTAssert(connection.directionBTracks.contains { $0 === change.previous })
            XCTAssert(connection.directionBTracks.contains { $0 === change.next })
        }
    } else {
        XCTAssert(connection.directionBTracks.isEmpty)
    }
}
