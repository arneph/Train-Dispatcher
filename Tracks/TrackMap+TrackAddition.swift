//
//  TrackMap+Addition.swift
//  Tracks
//
//  Created by Arne Philipeit on 3/27/24.
//

import Base
import Foundation

extension TrackMap {
    internal struct TrackAdditionHandler: ChangeHandler {
        let change: () -> ChangeHandler
        var canChange: Bool { true }
        func performChange() -> ChangeHandler { change() }
    }

    public enum ConnectionOption {
        case none
        case toExistingTrack(Track, PathExtremity)
        case toExistingConnection(TrackConnection)
        case toNewConnection(Track, Position)
    }

    private enum NonMergingConnectionOption {
        case none
        case toExistingConnection(TrackConnection)
        case toNewConnection(Track, Position)

        init?(_ connectionOption: ConnectionOption) {
            switch connectionOption {
            case .none: self = .none
            case .toExistingTrack: return nil
            case .toExistingConnection(let connection):
                self = .toExistingConnection(connection)
            case .toNewConnection(let track, let x):
                self = .toNewConnection(track, x)
            }
        }
    }

    public func addTrack(
        withPath path: SomeFinitePath, startConnection: ConnectionOption,
        endConnection: ConnectionOption
    ) -> (Track, ChangeHandler) {
        let (track, updates, changeHandler) = {
            switch (startConnection, endConnection) {
            case (
                .toExistingTrack(let trackA, let extremityA),
                .toExistingTrack(let trackB, let extremityB)
            ):
                return merge(
                    trackA: trackA, trackAExtremity: extremityA, trackB: trackB,
                    trackBExtremity: extremityB, viaPath: path)
            case (.toExistingTrack(let existingTrack, let existingTrackExtremity), _):
                let (updates1, undo) = extend(
                    track: existingTrack, at: existingTrackExtremity, withPath: path, at: .start)
                let updates2 = make(
                    endConnection: NonMergingConnectionOption(endConnection)!,
                    ofTrack: existingTrack)
                return (existingTrack, updates1 + updates2, undo)
            case (_, .toExistingTrack(let existingTrack, let existingTrackExtremity)):
                let (updates1, undo) = extend(
                    track: existingTrack, at: existingTrackExtremity, withPath: path, at: .end)
                let updates2 = make(
                    startConnection: NonMergingConnectionOption(startConnection)!,
                    ofTrack: existingTrack)
                return (existingTrack, updates1 + updates2, undo)
            default:
                let newTrack = Track(id: trackIDGenerator.new(), path: path)
                let updates1 = make(
                    startConnection: NonMergingConnectionOption(startConnection)!, ofTrack: newTrack
                )
                let updates2 = make(
                    endConnection: NonMergingConnectionOption(endConnection)!, ofTrack: newTrack)
                let updates3 = [add(track: newTrack)]
                return (
                    newTrack,
                    updates1 + updates2 + updates3,
                    TrackRemovalHandler(change: { self.remove(oldTrack: newTrack) })
                )
            }
        }()
        updateObservers(updates)
        return (track, changeHandler)
    }

    private func merge(
        trackA: Track, trackAExtremity: PathExtremity, trackB: Track,
        trackBExtremity: PathExtremity, viaPath middlePath: SomeFinitePath
    ) -> (Track, [ObserverUpdate], ChangeHandler) {
        let (combinedPath, pathAUpdate, pathBUpdate) = TrackMap.merge(
            pathA: trackA.path, pathAExtremity: trackAExtremity, pathB: trackB.path,
            pathBExtremity: trackBExtremity, middlePath: middlePath)
        let newTrack = Track(id: trackIDGenerator.new(), path: combinedPath)
        let undoHandler = TrackRemovalHandler(change: {
            let (_, _, undoHandler) = self.removeSection(
                ofTrack: newTrack, from: trackA.path.length,
                to: trackA.path.length + middlePath.length)
            return undoHandler
        })
        let startConnection: TrackConnection? = trackA.connection(at: trackAExtremity.opposite)
        let endConnection: TrackConnection? = trackB.connection(at: trackBExtremity.opposite)
        var updates: [ObserverUpdate] = []
        if let startConnection = startConnection {
            updates.append(newTrack.setStartConnection(startConnection))
            updates.append(
                contentsOf: startConnection.replace(
                    oldTrack: trackA,
                    newTrack: newTrack))
            updates.append(
                observers_.createUpdate({
                    $0.connectionChanged(startConnection, onMap: self)
                }))
        }
        if let endConnection = endConnection {
            updates.append(newTrack.setEndConnection(endConnection))
            updates.append(
                contentsOf: endConnection.replace(
                    oldTrack: trackB,
                    newTrack: newTrack))
            updates.append(
                observers_.createUpdate({
                    $0.connectionChanged(endConnection, onMap: self)
                }))
        }
        updates.append(
            contentsOf: replace(
                oldTracksAndUpdateFuncs: [
                    (trackA, { (newTrack, pathAUpdate($0)) }),
                    (trackB, { (newTrack, pathBUpdate($0)) }),
                ],
                withTracks: [newTrack])
        )
        return (newTrack, updates, undoHandler)
    }

    private static func merge(
        pathA: SomeFinitePath, pathAExtremity: PathExtremity, pathB: SomeFinitePath,
        pathBExtremity: PathExtremity, middlePath: SomeFinitePath
    ) -> (
        combinedPath: SomeFinitePath, pathAUpdate: PositionUpdateFunc,
        pathBUpdate: PositionUpdateFunc
    ) {
        switch (pathAExtremity, pathBExtremity) {
        case (.start, .start):
            (
                SomeFinitePath.combine([pathA.reverse, middlePath, pathB])!, { pathA.length - $0 },
                { pathA.length + middlePath.length + $0 }
            )
        case (.start, .end):
            (
                SomeFinitePath.combine([pathA.reverse, middlePath, pathB.reverse])!,
                { pathA.length - $0 }, { pathA.length + middlePath.length + pathB.length - $0 }
            )
        case (.end, .start):
            (
                SomeFinitePath.combine([pathA, middlePath, pathB])!, { $0 },
                { pathA.length + middlePath.length + $0 }
            )
        case (.end, .end):
            (
                SomeFinitePath.combine([pathA, middlePath, pathB.reverse])!, { $0 },
                { pathA.length + middlePath.length + pathB.length - $0 }
            )
        }
    }

    private func extend(
        track existingTrack: Track, at existingTrackExtremity: PathExtremity,
        withPath newPath: SomeFinitePath, at newPathExtremity: PathExtremity
    ) -> ([ObserverUpdate], ChangeHandler) {
        let oldLength = existingTrack.path.length
        let (combinedPath, pathAUpdate) = TrackMap.merge(
            pathA: existingTrack.path, pathAExtremity: existingTrackExtremity, pathB: newPath,
            pathBExtremity: newPathExtremity)
        let undoHandler = TrackRemovalHandler(change: {
            let (_, _, undoHandler) = self.removeSection(
                ofTrack: existingTrack, from: oldLength, to: newPath.length)
            return undoHandler
        })
        let update1 = existingTrack.set(path: combinedPath, withPositionUpdate: pathAUpdate)
        let update2 = observers_.createUpdate({
            $0.trackChanged(existingTrack, onMap: self)
        })
        return ([update1, update2], undoHandler)
    }

    private static func merge(
        pathA: SomeFinitePath, pathAExtremity: PathExtremity, pathB: SomeFinitePath,
        pathBExtremity: PathExtremity
    ) -> (combinedPath: SomeFinitePath, pathAUpdate: PositionUpdateFunc) {
        switch (pathAExtremity, pathBExtremity) {
        case (.start, .start):
            (SomeFinitePath.combine(pathA.reverse, pathB)!, { pathA.length - $0 })
        case (.start, .end):
            (SomeFinitePath.combine(pathA.reverse, pathB.reverse)!, { pathA.length - $0 })
        case (.end, .start):
            (SomeFinitePath.combine(pathA, pathB)!, { $0 })
        case (.end, .end):
            (SomeFinitePath.combine(pathA, pathB.reverse)!, { $0 })
        }
    }

    private func make(startConnection: NonMergingConnectionOption, ofTrack track: Track)
        -> [ObserverUpdate]
    {
        switch startConnection {
        case .none:
            return []
        case .toExistingConnection(let connection):
            let updates1 = [track.setStartConnection(connection)]
            let updates2 = connection.add(track: track)
            let updates3 = [
                observers_.createUpdate({
                    $0.connectionChanged(connection, onMap: self)
                })
            ]
            return updates1 + updates2 + updates3
        case .toNewConnection(let existingTrack, let x):
            let (newConnection, updates1) = createNewConnection(
                toExistingTrack: existingTrack, at: x)
            let updates2 = [track.setStartConnection(newConnection)]
            let updates3 = newConnection.add(track: track)
            return updates1 + updates2 + updates3
        }
    }

    private func make(endConnection: NonMergingConnectionOption, ofTrack track: Track)
        -> [ObserverUpdate]
    {
        switch endConnection {
        case .none:
            return []
        case .toExistingConnection(let connection):
            let updates1 = [track.setEndConnection(connection)]
            let updates2 = connection.add(track: track)
            let updates3 = [
                observers_.createUpdate({
                    $0.connectionChanged(connection, onMap: self)
                })
            ]
            return updates1 + updates2 + updates3
        case .toNewConnection(let existingTrack, let x):
            let (newConnection, updates1) = createNewConnection(
                toExistingTrack: existingTrack, at: x)
            let updates2 = [track.setEndConnection(newConnection)]
            let updates3 = newConnection.add(track: track)
            return updates1 + updates2 + updates3
        }
    }

    private func createNewConnection(
        toExistingTrack existingTrack: Track,
        at x: Position
    ) -> (TrackConnection, [ObserverUpdate]) {
        if x == 0.0.m {
            let newConnection = TrackConnection(
                id: connectionIDGenerator.new(), point: existingTrack.path.start,
                directionA: existingTrack.path.startOrientation)
            let updates1 = newConnection.add(track: existingTrack)
            let updates2 = [existingTrack.setStartConnection(newConnection)]
            let updates3 = [add(connection: newConnection)]
            return (newConnection, updates1 + updates2 + updates3)
        } else if x == existingTrack.path.length {
            let newConnection = TrackConnection(
                id: connectionIDGenerator.new(), point: existingTrack.path.end,
                directionA: existingTrack.path.endOrientation)
            let updates1 = newConnection.add(track: existingTrack)
            let updates2 = [existingTrack.setEndConnection(newConnection)]
            let updates3 = [add(connection: newConnection)]
            return (newConnection, updates1 + updates2 + updates3)
        } else {
            return split(oldTrack: existingTrack, at: x)
        }
    }

    private func split(oldTrack: Track, at x: Position) -> (TrackConnection, [ObserverUpdate]) {
        assert(trackSet.contains(oldTrack))
        assert(0.0.m < x && x < oldTrack.path.length)
        let point = oldTrack.path.point(at: x)!
        let directionA = oldTrack.path.orientation(at: x)!
        let (splitPathA, splitPathB) = oldTrack.path.split(at: x)!
        let splitTrackA = Track(id: trackIDGenerator.new(), path: splitPathA)
        let splitTrackB = Track(id: trackIDGenerator.new(), path: splitPathB)
        var updates: [ObserverUpdate] = []
        if let connectionA = oldTrack.startConnection {
            updates.append(splitTrackA.setStartConnection(connectionA))
            updates.append(
                contentsOf: connectionA.replace(
                    oldTrack: oldTrack,
                    newTrack: splitTrackA))
        }
        if let connectionB = oldTrack.endConnection {
            updates.append(splitTrackB.setStartConnection(connectionB))
            updates.append(
                contentsOf: connectionB.replace(
                    oldTrack: oldTrack,
                    newTrack: splitTrackB))
        }
        let newConnection = TrackConnection(
            id: connectionIDGenerator.new(), point: point, directionA: directionA)
        updates.append(splitTrackA.setEndConnection(newConnection))
        updates.append(splitTrackB.setStartConnection(newConnection))
        updates.append(contentsOf: newConnection.add(track: splitTrackA))
        updates.append(contentsOf: newConnection.add(track: splitTrackB))
        updates.append(
            contentsOf: replace(
                oldTracksAndUpdateFuncs: [
                    (oldTrack, { (y) in (y < x) ? (splitTrackA, y) : (splitTrackB, y - x) })
                ],
                withTracks: [splitTrackA, splitTrackB]))
        updates.append(add(connection: newConnection))
        return (newConnection, updates)
    }

}
