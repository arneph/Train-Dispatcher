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
        var updates: [ObserverUpdate] = []
        updates.append(contentsOf: remove(track: oldTrack))
        if let startConnection = oldTrack.startConnection {
            updates.append(startConnection.remove(track: oldTrack))
            updates.append(contentsOf: mergeIfNecessary(oldConnection: startConnection))
        }
        if let endConnection = oldTrack.endConnection {
            updates.append(endConnection.remove(track: oldTrack))
            updates.append(contentsOf: mergeIfNecessary(oldConnection: endConnection))
        }
        updateObservers(updates)
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
        var updates: [ObserverUpdate] = []
        let newTrack1: Track?
        let newTrack2: Track?
        if start == 0.0.m && end == track.path.length {
            return (nil, nil, remove(oldTrack: track))
        } else if start == 0.0.m {
            if let startConnection = track.startConnection {
                updates.append(track.setStartConnection(nil))
                updates.append(startConnection.remove(track: track))
                updates.append(contentsOf: mergeIfNecessary(oldConnection: startConnection))
            }
            let (_, cutPath) = track.path.split(at: end)!
            updates.append(
                track.set(
                    path: cutPath,
                    withPositionUpdate: { x in
                        x - end
                    }))
            updates.append(
                observers_.createUpdate({
                    $0.trackChanged(track, onMap: self)
                }))
            newTrack1 = nil
            newTrack2 = track
        } else if end == track.path.length {
            if let endConnection = track.endConnection {
                updates.append(track.setEndConnection(nil))
                updates.append(endConnection.remove(track: track))
                updates.append(contentsOf: mergeIfNecessary(oldConnection: endConnection))
            }
            let (cutPath, _) = track.path.split(at: start)!
            updates.append(
                track.set(
                    path: cutPath,
                    withPositionUpdate: { x in
                        x
                    }))
            updates.append(
                observers_.createUpdate({
                    $0.trackChanged(track, onMap: self)
                }))
            newTrack1 = track
            newTrack2 = nil
        } else {
            let trackLength = track.path.length
            let (pathA, _, pathB) = track.path.split(at: start, and: end)!
            let trackA = Track(id: trackIDGenerator.new(), path: pathA)
            let trackB = Track(id: trackIDGenerator.new(), path: pathB)
            updates.append(
                contentsOf:
                    replace(
                        oldTracksAndUpdateFuncs: [
                            (
                                track,
                                { x in
                                    if 0.0.m <= x && x <= start {
                                        (trackA, x)
                                    } else if end <= x && x <= trackLength {
                                        (trackB, x - end)
                                    } else {
                                        nil
                                    }
                                }
                            )
                        ],
                        withTracks: [trackA, trackB]))
            if let startConnection = track.startConnection {
                updates.append(trackA.setStartConnection(startConnection))
                updates.append(
                    contentsOf: startConnection.replace(
                        oldTrack: track,
                        newTrack: trackA))
            }
            if let endConnection = track.endConnection {
                updates.append(trackB.setEndConnection(endConnection))
                updates.append(
                    contentsOf: endConnection.replace(
                        oldTrack: track,
                        newTrack: trackB))
            }
            newTrack1 = trackA
            newTrack2 = trackB
        }
        updateObservers(updates)
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

    private func mergeIfNecessary(oldConnection: TrackConnection) -> [ObserverUpdate] {
        guard oldConnection.directionATracks.count == 1, oldConnection.directionBTracks.count == 1
        else {
            return []
        }
        var updates: [ObserverUpdate] = []
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
        updates.append(combinedTrack.setStartConnection(startConnection))
        updates.append(combinedTrack.setEndConnection(endConnection))
        updates.append(
            contentsOf: startConnection?.replace(
                oldTrack: oldTrackA,
                newTrack: combinedTrack) ?? [])
        updates.append(
            contentsOf: endConnection?.replace(
                oldTrack: oldTrackB,
                newTrack: combinedTrack) ?? [])
        let oldTrackALength = oldTrackA.path.length
        let oldTrackBLength = oldTrackB.path.length
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
        if oldTrackB.startConnection === oldConnection {
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
        updates.append(
            contentsOf: replace(
                oldTracksAndUpdateFuncs: [
                    (oldTrackA, oldTrackAUpdateFunc),
                    (oldTrackB, oldTrackBUpdateFunc),
                ],
                withTracks: [combinedTrack]))
        updates.append(contentsOf: remove(connection: oldConnection))
        return updates
    }
}
