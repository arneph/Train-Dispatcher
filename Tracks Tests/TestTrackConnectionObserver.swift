//
//  TestTrackConnectionObserver.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 1/27/24.
//

import Base
import Foundation

@testable import Tracks

extension TrackConnection.StateChange: @retroactive Equatable {
    public static func == (
        lhs: Tracks.TrackConnection.StateChange,
        rhs: Tracks.TrackConnection.StateChange
    ) -> Bool {
        lhs.previous === rhs.previous && lhs.next === rhs.next && lhs.progress == rhs.progress
    }
}

extension TrackConnection.State: @retroactive Equatable {
    public static func == (
        lhs: Tracks.TrackConnection.State,
        rhs: Tracks.TrackConnection.State
    ) -> Bool {
        switch (lhs, rhs) {
        case (.fixed(let lt), .fixed(let rt)): lt === rt
        case (.changing(let lc), .changing(let rc)): lc == rc
        default:
            false
        }
    }
}

final class TestTrackConnectionObserver: TrackConnectionObserver {
    enum Call: Equatable {
        case addedTrack(Track, TrackConnection, TrackConnection.Direction)
        case replacedTrack(Track, Track, TrackConnection, TrackConnection.Direction)
        case removedTrack(Track, TrackConnection)
        case startedChangingState(TrackConnection, TrackConnection.Direction)
        case progressedStateChange(TrackConnection, TrackConnection.Direction)
        case stoppedChangingState(TrackConnection, TrackConnection.Direction)
        case removed(TrackConnection)

        static func == (lhs: Call, rhs: Call) -> Bool {
            switch (lhs, rhs) {
            case (.addedTrack(let lt, let lc, let ld), .addedTrack(let rt, let rc, let rd)):
                lt === rt && lc === rc && ld == rd
            case (
                .replacedTrack(let lo, let ln, let lc, let ld),
                .replacedTrack(let ro, let rn, let rc, let rd)
            ):
                lo === ro && ln === rn && lc === rc && ld == rd
            case (.removedTrack(let lt, let lc), .removedTrack(let rt, let rc)):
                lt === rt && lc === rc
            case (.startedChangingState(let lc, let ld), .startedChangingState(let rc, let rd)):
                lc === rc && ld == rd
            case (.progressedStateChange(let lc, let ld), .progressedStateChange(let rc, let rd)):
                lc === rc && ld == rd
            case (.stoppedChangingState(let lc, let ld), .stoppedChangingState(let rc, let rd)):
                lc === rc && ld == rd
            case (.removed(let lc), .removed(let rc)):
                lc === rc
            default:
                false
            }
        }
    }
    var calls: [Call] = []

    init(for connection: TrackConnection) {
        connection.add(observer: self)
    }

    func added(
        track newTrack: Track, toConnection connection: TrackConnection,
        inDirection direction: TrackConnection.Direction
    ) {
        calls.append(.addedTrack(newTrack, connection, direction))
    }

    func replaced(
        track oldTrack: Track, withTrack newTrack: Track, inConnection connection: TrackConnection,
        inDirection direction: TrackConnection.Direction
    ) {
        calls.append(.replacedTrack(oldTrack, newTrack, connection, direction))
    }

    func removed(track oldTrack: Track, fromConnection connection: TrackConnection) {
        calls.append(.removedTrack(oldTrack, connection))
    }

    func removed(connection oldConnection: TrackConnection) {
        calls.append(.removed(oldConnection))
    }

}
