//
//  TrackConnection+Modifications.swift
//  Tracks
//
//  Created by Arne Philipeit on 9/15/24.
//

import Base
import Foundation

extension TrackConnection {
    internal func add(track: Track) {
        assert(track.path.start == point || track.path.end == point)
        if track.path.startPointAndOrientation == pointAndDirectionA
            || track.path.endPointAndOrientation == pointAndDirectionB
        {
            directionATracks.append(track)
            if directionATracks.count == 1 {
                directionAState = .fixed(track)
            }
            observers.forEach { $0.added(track: track, toConnection: self, inDirection: .a) }
        }
        if track.path.startPointAndOrientation == pointAndDirectionB
            || track.path.endPointAndOrientation == pointAndDirectionA
        {
            directionBTracks.append(track)
            if directionBTracks.count == 1 {
                directionBState = .fixed(track)
            }
            observers.forEach { $0.added(track: track, toConnection: self, inDirection: .b) }
        }
    }

    internal func replace(oldTrack: Track, newTrack: Track) {
        if directionATracks.contains(where: { $0 === oldTrack }) {
            directionATracks.removeAll { $0 === oldTrack }
            directionATracks.append(newTrack)
            directionAState = TrackConnection.replace(
                in: directionAState,
                oldTrack: oldTrack,
                newTrack: newTrack)
            observers.forEach {
                $0.replaced(
                    track: oldTrack, withTrack: newTrack, inConnection: self, inDirection: .a)
            }
        }
        if directionBTracks.contains(where: { $0 === oldTrack }) {
            directionBTracks.removeAll { $0 === oldTrack }
            directionBTracks.append(newTrack)
            directionBState = TrackConnection.replace(
                in: directionBState,
                oldTrack: oldTrack,
                newTrack: newTrack)
            observers.forEach {
                $0.replaced(
                    track: oldTrack, withTrack: newTrack, inConnection: self, inDirection: .b)
            }
        }
    }

    private static func replace(
        in state: State?,
        oldTrack: Track,
        newTrack: Track
    ) -> State? {
        switch state {
        case .fixed(let track):
            if track === oldTrack {
                .fixed(newTrack)
            } else {
                .fixed(track)
            }
        case .changing(let change):
            .changing(
                StateChange(
                    previous: change.previous === oldTrack ? newTrack : change.previous,
                    next: change.next === oldTrack ? newTrack : change.next,
                    progress: change.progress))
        case nil:
            nil
        }
    }

    internal func remove(track: Track) {
        directionATracks.removeAll { $0 === track }
        directionAState = TrackConnection.remove(
            in: directionAState,
            oldTrack: track,
            potentialNewTrack: directionATracks.first)
        directionBTracks.removeAll { $0 === track }
        directionBState = TrackConnection.remove(
            in: directionBState,
            oldTrack: track,
            potentialNewTrack: directionBTracks.first)
        observers.forEach { $0.removed(track: track, fromConnection: self) }
    }

    private static func remove(in state: State?, oldTrack: Track, potentialNewTrack: Track?)
        -> State?
    {
        switch state {
        case .fixed(let track):
            if oldTrack === track {
                if let newTrack = potentialNewTrack {
                    .fixed(newTrack)
                } else {
                    nil
                }
            } else {
                .fixed(track)
            }
        case .changing(let change):
            if change.next === oldTrack {
                if let newTrack = potentialNewTrack {
                    .fixed(newTrack)
                } else {
                    nil
                }
            } else if change.previous === oldTrack {
                .fixed(change.next)
            } else {
                .changing(change)
            }
        case nil:
            nil
        }
    }

    internal func informObserversOfRemoval() {
        observers.forEach { $0.removed(connection: self) }
    }
}
