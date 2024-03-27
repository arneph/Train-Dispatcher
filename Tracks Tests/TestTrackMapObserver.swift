//
//  TestTrackMapObserver.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/26/24.
//

import Base
import Foundation

@testable import Tracks

final class TestTrackMapObserver: TrackMapObserver {
    enum Call: Equatable {
        case addedTrack(Track, TrackMap)
        case replacedTrack(Track, [Track], TrackMap)
        case removedTrack(Track, TrackMap)
        case addedConnection(TrackConnection, TrackMap)
        case removedConnection(TrackConnection, TrackMap)
        case trackChanged(Track, TrackMap)
        case connectionChanged(TrackConnection, TrackMap)

        static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case (.addedTrack(let lt, let lm), .addedTrack(let rt, let rm)):
                lt === rt && lm === rm
            case (.replacedTrack(let lo, let ln, let lm), .replacedTrack(let ro, let rn, let rm)):
                lo === ro && zip(ln, rn).allSatisfy { $0 === $1 } && lm === rm
            case (.removedTrack(let lt, let lm), .removedTrack(let rt, let rm)):
                lt === rt && lm === rm
            case (.addedConnection(let lc, let lm), .addedConnection(let rc, let rm)):
                lc === rc && lm === rm
            case (.removedConnection(let lc, let lm), .removedConnection(let rc, let rm)):
                lc === rc && lm === rm
            case (.trackChanged(let lt, let lm), .trackChanged(let rt, let rm)):
                lt === rt && lm === rm
            case (.connectionChanged(let lc, let lm), .connectionChanged(let rc, let rm)):
                lc === rc && lm === rm
            default:
                false
            }
        }
    }
    var calls: [Call] = []

    init(for map: TrackMap) {
        map.add(observer: self)
    }

    func added(track: Track, toMap map: TrackMap) {
        calls.append(.addedTrack(track, map))
    }

    func replaced(track oldTrack: Track, withTracks newTracks: [Track], onMap map: TrackMap) {
        calls.append(.replacedTrack(oldTrack, newTracks, map))
    }

    func removed(track oldTrack: Track, fromMap map: TrackMap) {
        calls.append(.removedTrack(oldTrack, map))
    }

    func added(connection: TrackConnection, toMap map: TrackMap) {
        calls.append(.addedConnection(connection, map))
    }

    func removed(connection oldConnection: TrackConnection, fromMap map: TrackMap) {
        calls.append(.removedConnection(oldConnection, map))
    }

    func trackChanged(_ track: Track, onMap map: TrackMap) {
        calls.append(.trackChanged(track, map))
    }

    func connectionChanged(_ connection: TrackConnection, onMap map: TrackMap) {
        calls.append(.connectionChanged(connection, map))
    }

}
