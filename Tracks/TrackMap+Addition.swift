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
        switch (startConnection, endConnection) {
        case (
            .toExistingTrack(let trackA, let extremityA),
            .toExistingTrack(let trackB, let extremityB)
        ):
            return merge(
                trackA: trackA, trackAExtremity: extremityA, trackB: trackB,
                trackBExtremity: extremityB, viaPath: path)
        case (.toExistingTrack(let existingTrack, let existingTrackExtremity), _):
            let undo = extend(
                track: existingTrack, at: existingTrackExtremity, withPath: path, at: .start)
            make(endConnection: NonMergingConnectionOption(endConnection)!, ofTrack: existingTrack)
            return (existingTrack, undo)
        case (_, .toExistingTrack(let existingTrack, let existingTrackExtremity)):
            let undo = extend(
                track: existingTrack, at: existingTrackExtremity, withPath: path, at: .end)
            make(
                startConnection: NonMergingConnectionOption(startConnection)!,
                ofTrack: existingTrack)
            return (existingTrack, undo)
        default:
            let newTrack = Track(id: trackIDGenerator.new(), path: path)
            make(startConnection: NonMergingConnectionOption(startConnection)!, ofTrack: newTrack)
            make(endConnection: NonMergingConnectionOption(endConnection)!, ofTrack: newTrack)
            trackSet.add(newTrack)
            observers.forEach { $0.added(track: newTrack, toMap: self) }
            return (newTrack, TrackRemovalHandler(change: { self.remove(oldTrack: newTrack) }))
        }
    }

    private func merge(
        trackA: Track, trackAExtremity: PathExtremity, trackB: Track,
        trackBExtremity: PathExtremity, viaPath middlePath: SomeFinitePath
    ) -> (Track, ChangeHandler) {
        let (combinedPath, pathAUpdate, pathBUpdate) = TrackMap.merge(
            pathA: trackA.path, pathAExtremity: trackAExtremity, pathB: trackB.path,
            pathBExtremity: trackBExtremity, middlePath: middlePath)
        let newTrack = Track(id: trackIDGenerator.new(), path: combinedPath)
        let undoHandler = TrackRemovalHandler(change: {
            self.removeSection(
                ofTrack: newTrack, from: trackA.path.length,
                to: trackA.path.length + middlePath.length)
        })
        let startConnection: TrackConnection? = trackA.connection(at: trackAExtremity.opposite)
        let endConnection: TrackConnection? = trackB.connection(at: trackBExtremity.opposite)
        newTrack.startConnection = startConnection
        newTrack.endConnection = endConnection
        trackSet.add(newTrack)
        trackSet.remove(trackA)
        trackSet.remove(trackB)
        if let startConnection = startConnection {
            startConnection.replace(oldTrack: trackA, newTrack: newTrack)
            observers.forEach { $0.connectionChanged(startConnection, onMap: self) }
        }
        if let endConnection = endConnection {
            endConnection.replace(oldTrack: trackB, newTrack: newTrack)
            observers.forEach { $0.connectionChanged(endConnection, onMap: self) }
        }
        trackA.informObserversOfReplacement(
            by: [newTrack], withUpdateFunc: { (newTrack, pathAUpdate($0)) })
        trackB.informObserversOfReplacement(
            by: [newTrack], withUpdateFunc: { (newTrack, pathBUpdate($0)) })
        observers.forEach { $0.replaced(track: trackA, withTracks: [newTrack], onMap: self) }
        observers.forEach { $0.replaced(track: trackB, withTracks: [newTrack], onMap: self) }
        return (newTrack, undoHandler)
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
    ) -> ChangeHandler {
        let oldLength = existingTrack.path.length
        let (combinedPath, pathAUpdate) = TrackMap.merge(
            pathA: existingTrack.path, pathAExtremity: existingTrackExtremity, pathB: newPath,
            pathBExtremity: newPathExtremity)
        let undoHandler = TrackRemovalHandler(change: {
            self.removeSection(ofTrack: existingTrack, from: oldLength, to: newPath.length)
        })
        existingTrack.set(path: combinedPath, withPositionUpdate: pathAUpdate)
        observers.forEach { $0.trackChanged(existingTrack, onMap: self) }
        return undoHandler
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

    private func make(startConnection: NonMergingConnectionOption, ofTrack track: Track) {
        switch startConnection {
        case .none:
            break
        case .toExistingConnection(let connection):
            track.startConnection = connection
            connection.add(track: track)
            observers.forEach { $0.connectionChanged(connection, onMap: self) }
        case .toNewConnection(let existingTrack, let x):
            let newConnection = createNewConnection(toExistingTrack: existingTrack, at: x)
            track.startConnection = newConnection
            newConnection.add(track: track)
        }
    }

    private func make(endConnection: NonMergingConnectionOption, ofTrack track: Track) {
        switch endConnection {
        case .none:
            break
        case .toExistingConnection(let connection):
            track.endConnection = connection
            connection.add(track: track)
            observers.forEach { $0.connectionChanged(connection, onMap: self) }
        case .toNewConnection(let existingTrack, let x):
            let newConnection = createNewConnection(toExistingTrack: existingTrack, at: x)
            track.endConnection = newConnection
            newConnection.add(track: track)
        }
    }

    private func createNewConnection(
        toExistingTrack existingTrack: Track,
        at x: Position
    ) -> TrackConnection {
        let newConnection: TrackConnection
        if x == 0.0.m {
            newConnection = TrackConnection(
                id: connectionIDGenerator.new(), point: existingTrack.path.start,
                directionA: existingTrack.path.startOrientation)
            newConnection.add(track: existingTrack)
            existingTrack.startConnection = newConnection
            connectionSet.add(newConnection)
            observers.forEach { $0.added(connection: newConnection, toMap: self) }
        } else if x == existingTrack.path.length {
            newConnection = TrackConnection(
                id: connectionIDGenerator.new(), point: existingTrack.path.end,
                directionA: existingTrack.path.endOrientation)
            newConnection.add(track: existingTrack)
            existingTrack.endConnection = newConnection
            connectionSet.add(newConnection)
            observers.forEach { $0.added(connection: newConnection, toMap: self) }
        } else {
            newConnection = split(oldTrack: existingTrack, at: x)
        }
        return newConnection
    }

    private func split(oldTrack: Track, at x: Position) -> TrackConnection {
        assert(trackSet.contains(oldTrack))
        assert(0.0.m < x && x < oldTrack.path.length)
        let point = oldTrack.path.point(at: x)!
        let directionA = oldTrack.path.orientation(at: x)!
        let (splitPathA, splitPathB) = oldTrack.path.split(at: x)!
        let splitTrackA = Track(id: trackIDGenerator.new(), path: splitPathA)
        let splitTrackB = Track(id: trackIDGenerator.new(), path: splitPathB)
        if let connectionA = oldTrack.startConnection {
            splitTrackA.startConnection = connectionA
            connectionA.replace(oldTrack: oldTrack, newTrack: splitTrackA)
        }
        if let connectionB = oldTrack.endConnection {
            splitTrackB.endConnection = connectionB
            connectionB.replace(oldTrack: oldTrack, newTrack: splitTrackB)
        }
        let newConnection = TrackConnection(
            id: connectionIDGenerator.new(), point: point, directionA: directionA)
        splitTrackA.endConnection = newConnection
        splitTrackB.startConnection = newConnection
        newConnection.add(track: splitTrackA)
        newConnection.add(track: splitTrackB)
        trackSet.remove(oldTrack)
        trackSet.add(splitTrackA)
        trackSet.add(splitTrackB)
        connectionSet.add(newConnection)
        oldTrack.informObserversOfReplacement(
            by: [splitTrackA, splitTrackB],
            withUpdateFunc: { (y) in
                (y < x) ? (splitTrackA, y) : (splitTrackB, y - x)
            })
        observers.forEach {
            $0.replaced(track: oldTrack, withTracks: [splitTrackA, splitTrackB], onMap: self)
        }
        observers.forEach { $0.added(connection: newConnection, toMap: self) }
        return newConnection
    }

}
