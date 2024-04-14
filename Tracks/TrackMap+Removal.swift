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

    public func removeSection(ofTrack track: Track, from start: Position, to end: Position)
        -> (Track?, Track?, ChangeHandler)
    {
        let newTrack1: Track?
        let newTrack2: Track?
        if start == 0.0.m && end == track.path.length {
            return (nil, nil, remove(oldTrack: track))
        } else if start == 0.0.m {
            if let startConnection = track.startConnection {
                track.startConnection = nil
                startConnection.remove(track: track)
                mergeIfNecessary(oldConnection: startConnection)
            }
            let (_, cutPath) = track.path.split(at: end)!
            track.set(
                path: cutPath,
                withPositionUpdate: { x in
                    x - end
                })
            observers.forEach { $0.trackChanged(track, onMap: self) }
            newTrack1 = nil
            newTrack2 = track
        } else if end == track.path.length {
            if let endConnection = track.endConnection {
                track.endConnection = nil
                endConnection.remove(track: track)
                mergeIfNecessary(oldConnection: endConnection)
            }
            let (cutPath, _) = track.path.split(at: start)!
            track.set(
                path: cutPath,
                withPositionUpdate: { x in
                    x
                })
            observers.forEach { $0.trackChanged(track, onMap: self) }
            newTrack1 = track
            newTrack2 = nil
        } else {
            let trackLength = track.path.length
            let (pathA, _, pathB) = track.path.split(at: start, and: end)!
            let trackA = Track(id: trackIDGenerator.new(), path: pathA)
            let trackB = Track(id: trackIDGenerator.new(), path: pathB)
            trackSet.remove(track)
            trackSet.add(trackA)
            trackSet.add(trackB)
            if let startConnection = track.startConnection {
                trackA.startConnection = startConnection
                startConnection.replace(oldTrack: track, newTrack: trackA)
            }
            if let endConnection = track.endConnection {
                trackB.endConnection = endConnection
                endConnection.replace(oldTrack: track, newTrack: trackB)
            }
            track.informObserversOfReplacement(
                by: [trackA, trackB],
                withUpdateFunc: { x in
                    if 0.0.m <= x && x <= start {
                        (trackA, x)
                    } else if end <= x && x <= trackLength {
                        (trackB, x - end)
                    } else {
                        nil
                    }
                })
            observers.forEach {
                $0.replaced(track: track, withTracks: [trackA, trackB], onMap: self)
            }
            newTrack1 = trackA
            newTrack2 = trackB
        }
        return (
            newTrack1, newTrack2,
            TrackAdditionHandler(change: {
                // TODO: return actual change handler
                let path = LinearPath(
                    start: Point(x: 100.0.m, y: 100.0.m), end: Point(x: 200.0.m, y: 100.0.m))!
                let (_, undoHandler) = self.addTrack(
                    withPath: .linear(path), startConnection: .none, endConnection: .none)
                return undoHandler
            })
        )
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
        let oldTrackALength = oldTrackA.path.length
        let oldTrackBLength = oldTrackA.path.length
        let oldTrackAUpdateFunc: TrackAndPostionUpdateFunc
        let oldTrackBUpdateFunc: TrackAndPostionUpdateFunc
        if oldTrackA.endConnection === oldConnection {
            oldTrackAUpdateFunc = { x in
                if 0.0.m <= x && x <= oldTrackALength {
                    (combinedTrack, x)
                } else {
                    nil
                }
            }
        } else {
            oldTrackAUpdateFunc = { x in
                if 0.0.m <= x && x <= oldTrackALength {
                    (combinedTrack, oldTrackALength - x)
                } else {
                    nil
                }
            }
        }
        if oldTrackB.endConnection === oldConnection {
            oldTrackBUpdateFunc = { x in
                if 0.0.m <= x && x <= oldTrackBLength {
                    (combinedTrack, oldTrackALength + x)
                } else {
                    nil
                }
            }
        } else {
            oldTrackBUpdateFunc = { x in
                if 0.0.m <= x && x <= oldTrackBLength {
                    (combinedTrack, oldTrackALength + oldTrackBLength - x)
                } else {
                    nil
                }
            }
        }
        trackSet.remove(oldTrackA)
        trackSet.remove(oldTrackB)
        trackSet.add(combinedTrack)
        connectionSet.remove(oldConnection)
        oldTrackA.informObserversOfReplacement(
            by: [combinedTrack], withUpdateFunc: oldTrackAUpdateFunc)
        oldTrackB.informObserversOfReplacement(
            by: [combinedTrack], withUpdateFunc: oldTrackBUpdateFunc)
        oldConnection.informObserversOfRemoval()
        observers.forEach {
            $0.replaced(track: oldTrackA, withTracks: [combinedTrack], onMap: self)
        }
        observers.forEach {
            $0.replaced(track: oldTrackB, withTracks: [combinedTrack], onMap: self)
        }
        observers.forEach { $0.removed(connection: oldConnection, fromMap: self) }
    }
}
