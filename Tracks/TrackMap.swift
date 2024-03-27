//
//  Tracks.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Base
import Foundation

public final class TrackMap {
    private var observers: [TrackMapObserver] = []
    public func add(observer: TrackMapObserver) { observers.append(observer) }
    public func remove(observer: TrackMapObserver) { observers.removeAll { $0 === observer } }

    private let trackIDGenerator = IDGenerator<Track>()
    private let connectionIDGenerator = IDGenerator<TrackConnection>()

    private var trackSet = IDSet<Track>()
    private var connectionSet = IDSet<TrackConnection>()

    public var tracks: [Track] { trackSet.elements }
    public var connections: [TrackConnection] { connectionSet.elements }

    private struct TrackAdditionHandler: ChangeHandler {
        let change: () -> ChangeHandler
        var canChange: Bool { true }
        func performChange() -> ChangeHandler { change() }
    }

    private struct TrackRemovalHandler: ChangeHandler {
        let change: () -> ChangeHandler
        var canChange: Bool { true }  // TODO: check for occupancy in the future
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
        let (x, y, z) = (trackA.path.length, middlePath.length, trackB.path.length)
        let combinedPath: SomeFinitePath
        let trackAUpdate: PositionUpdateFunc
        let trackBUpdate: PositionUpdateFunc
        let startConnection: TrackConnection?
        let endConnection: TrackConnection?
        switch (trackAExtremity, trackBExtremity) {
        case (.start, .start):
            combinedPath = SomeFinitePath.combine([trackA.path.reverse, middlePath, trackB.path])!
            trackAUpdate = { x - $0 }
            trackBUpdate = { x + y + $0 }
            startConnection = trackA.endConnection
            endConnection = trackB.endConnection
        case (.start, .end):
            combinedPath = SomeFinitePath.combine([
                trackA.path.reverse, middlePath, trackB.path.reverse,
            ])!
            trackAUpdate = { x - $0 }
            trackBUpdate = { x + y + z - $0 }
            startConnection = trackA.endConnection
            endConnection = trackB.startConnection
        case (.end, .start):
            combinedPath = SomeFinitePath.combine([trackA.path, middlePath, trackB.path])!
            trackAUpdate = { $0 }
            trackBUpdate = { x + y + $0 }
            startConnection = trackA.startConnection
            endConnection = trackB.endConnection
        case (.end, .end):
            combinedPath = SomeFinitePath.combine([trackA.path, middlePath, trackB.path.reverse])!
            trackAUpdate = { $0 }
            trackBUpdate = { x + y + z - $0 }
            startConnection = trackA.startConnection
            endConnection = trackB.startConnection
        }
        let newTrack = Track(id: trackIDGenerator.new(), path: combinedPath)
        let undoHandler = TrackRemovalHandler(change: {
            self.removeSection(
                ofTrack: newTrack, from: trackA.path.length,
                to: trackA.path.length + middlePath.length)
        })
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
            by: [newTrack], withUpdateFunc: { (newTrack, trackAUpdate($0)) })
        trackB.informObserversOfReplacement(
            by: [newTrack], withUpdateFunc: { (newTrack, trackBUpdate($0)) })
        observers.forEach { $0.replaced(track: trackA, withTracks: [newTrack], onMap: self) }
        observers.forEach { $0.replaced(track: trackB, withTracks: [newTrack], onMap: self) }
        return (newTrack, undoHandler)
    }

    private func extend(
        track existingTrack: Track, at existingTrackExtremity: PathExtremity,
        withPath newPath: SomeFinitePath, at newPathExtremity: PathExtremity
    ) -> ChangeHandler {
        let combinedPath: SomeFinitePath
        let xOffset: Distance
        let undoHandler: ChangeHandler
        switch (existingTrackExtremity, newPathExtremity) {
        case (.end, .start):
            combinedPath = SomeFinitePath.combine(existingTrack.path, newPath)!
            xOffset = 0.0.m
            undoHandler = TrackRemovalHandler(change: {
                self.removeSection(
                    ofTrack: existingTrack, from: existingTrack.path.length, to: combinedPath.length
                )
            })
        case (.end, .end):
            combinedPath = SomeFinitePath.combine(existingTrack.path, newPath.reverse)!
            xOffset = 0.0.m
            undoHandler = TrackRemovalHandler(change: {
                self.removeSection(
                    ofTrack: existingTrack, from: existingTrack.path.length, to: combinedPath.length
                )
            })
        case (.start, .start):
            combinedPath = SomeFinitePath.combine(newPath.reverse, existingTrack.path)!
            xOffset = newPath.length
            undoHandler = TrackRemovalHandler(change: {
                self.removeSection(ofTrack: existingTrack, from: 0.0.m, to: newPath.length)
            })
        case (.start, .end):
            combinedPath = SomeFinitePath.combine(newPath, existingTrack.path)!
            xOffset = newPath.length
            undoHandler = TrackRemovalHandler(change: {
                self.removeSection(ofTrack: existingTrack, from: 0.0.m, to: newPath.length)
            })
        }
        existingTrack.set(path: combinedPath, positionOffset: xOffset)
        observers.forEach { $0.trackChanged(existingTrack, onMap: self) }
        return undoHandler
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
            track.endConnection = newConnection
            newConnection.add(track: track)
        }
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

    public init() {}
    internal init(tracks: IDSet<Track>, connections: IDSet<TrackConnection>) {
        self.trackSet = tracks
        self.connectionSet = connections
    }

    deinit {
        observers = []
    }

}
