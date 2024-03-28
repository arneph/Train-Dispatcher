//
//  TrackMap+Removal.swift
//  Tracks
//
//  Created by Arne Philipeit on 3/27/24.
//

import Base
import Foundation

extension TrackMap {
    internal struct TrackRemovalHandler: ChangeHandler {
        let change: () -> ChangeHandler
        var canChange: Bool { true }  // TODO: check for occupancy in the future
        func performChange() -> ChangeHandler { change() }
    }

    public func remove(oldTrack: Track) -> ChangeHandler {
        trackSet.remove(oldTrack)
        if let startConnection = oldTrack.startConnection {
            startConnection.remove(track: oldTrack)
            mergeIfNecessary(oldConnection: startConnection)
        }
        if let endConnection = oldTrack.endConnection {
            endConnection.remove(track: oldTrack)
            mergeIfNecessary(oldConnection: endConnection)
        }
        oldTrack.informObserversOfRemoval()
        observers.forEach { $0.removed(track: oldTrack, fromMap: self) }
        return TrackAdditionHandler(change: {
            // TODO: reestablish start and end connections
            let (_, undoHandler) = self.addTrack(
                withPath: oldTrack.path, startConnection: .none, endConnection: .none)
            return undoHandler
        })
    }

    public func removeSection(ofTrack: Track, from start: Position, to end: Position)
        -> ChangeHandler
    {
        // TODO: implement
        TrackAdditionHandler(change: {
            // TODO: return actual change handler
            let path = LinearPath(
                start: Point(x: 100.0.m, y: 100.0.m), end: Point(x: 200.0.m, y: 100.0.m))!
            let (_, undoHandler) = self.addTrack(
                withPath: .linear(path), startConnection: .none, endConnection: .none)
            return undoHandler
        })
    }

    private func mergeIfNecessary(oldConnection: TrackConnection) {
        guard oldConnection.directionATracks.count == 1, oldConnection.directionBTracks.count == 1
        else {
            return
        }
        let oldTrackA = oldConnection.directionATracks.first!
        let oldPathA: SomeFinitePath
        let startConnection: TrackConnection?
        if oldTrackA.endConnection === oldConnection {
            oldPathA = oldTrackA.path
            startConnection = oldTrackA.startConnection
        } else {
            oldPathA = oldTrackA.path.reverse
            startConnection = oldTrackA.endConnection
        }
        let oldTrackB = oldConnection.directionBTracks.first!
        let oldPathB: SomeFinitePath
        let endConnection: TrackConnection?
        if oldTrackB.startConnection === oldConnection {
            oldPathB = oldTrackB.path
            endConnection = oldTrackB.endConnection
        } else {
            oldPathB = oldTrackB.path.reverse
            endConnection = oldTrackB.startConnection
        }
        let combinedPath = SomeFinitePath.combine(oldPathA, oldPathB)!
        let combinedTrack = Track(id: trackIDGenerator.new(), path: combinedPath)
        combinedTrack.startConnection = startConnection
        combinedTrack.endConnection = endConnection
        trackSet.remove(oldTrackA)
        trackSet.remove(oldTrackB)
        trackSet.add(combinedTrack)
        connectionSet.remove(oldConnection)
    }
}
