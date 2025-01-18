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
            let (_, cutPathAndMapping) = track.path.withMapping.split(at: end)!
            updates.append(
                track.set(
                    path: cutPathAndMapping.path,
                    withMapping: cutPathAndMapping.mapping))
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
            let (cutPathAndMapping, _) = track.path.withMapping.split(at: start)!
            updates.append(
                track.set(
                    path: cutPathAndMapping.path,
                    withMapping: cutPathAndMapping.mapping))
            updates.append(
                observers_.createUpdate({
                    $0.trackChanged(track, onMap: self)
                }))
            newTrack1 = track
            newTrack2 = nil
        } else {
            let (pathAAndMapping, _, pathBAndMapping) =
                track.path.withMapping.split(at: start, and: end)!
            let trackA = Track(id: trackIDGenerator.new(), path: pathAAndMapping.path)
            let trackB = Track(id: trackIDGenerator.new(), path: pathBAndMapping.path)
            updates.append(
                contentsOf:
                    replace(
                        oldTracksAndMappings: [
                            (
                                track,
                                TrackAndPostionMapping(tracksAndPositionMappings: [
                                    (trackA, pathAAndMapping.mapping),
                                    (trackB, pathBAndMapping.mapping),
                                ])
                            )
                        ], withTracks: [trackA, trackB]))
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
        let oldTrackA = oldConnection.directionATracks.first!
        let (oldPathAAndMapping, startConnection) =
            if oldTrackA.endConnection === oldConnection {
                (oldTrackA.path.withMapping, oldTrackA.startConnection)
            } else {
                (oldTrackA.path.withMapping.reverse, oldTrackA.endConnection)
            }
        let oldTrackB = oldConnection.directionBTracks.first!
        let (oldPathBAndMapping, endConnection) =
            if oldTrackB.startConnection === oldConnection {
                (oldTrackB.path.withMapping, oldTrackB.endConnection)
            } else {
                (oldTrackB.path.withMapping.reverse, oldTrackB.startConnection)
            }
        let (combinedPath, pathAMapping, pathBMapping) = FinitePathAndPositionMapping.combine(
            oldPathAAndMapping, oldPathBAndMapping)!
        let combinedTrack = Track(id: trackIDGenerator.new(), path: combinedPath)
        var updates: [ObserverUpdate] = []
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
        updates.append(
            contentsOf: replace(
                oldTracksAndMappings: [
                    (
                        oldTrackA,
                        TrackAndPostionMapping(
                            track: combinedTrack,
                            mapping: pathAMapping)
                    ),
                    (
                        oldTrackB,
                        TrackAndPostionMapping(
                            track: combinedTrack,
                            mapping: pathBMapping)
                    ),
                ],
                withTracks: [combinedTrack]))
        updates.append(contentsOf: remove(connection: oldConnection))
        return updates
    }
}
