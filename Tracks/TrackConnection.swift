//
//  TrackConnection.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import Foundation

public final class TrackConnection: IDObject {
    public enum Direction: Int {
        case a, b
        var opposite: Direction { Direction(rawValue: 1 - self.rawValue)! }
    }

    private var observers: [TrackConnectionObserver] = []
    public func add(observer: TrackConnectionObserver) { observers.append(observer) }
    public func remove(observer: TrackConnectionObserver) {
        observers.removeAll { $0 === observer }
    }

    public let id: ID<TrackConnection>

    public let point: Point
    public let directionA: CircleAngle
    public var directionB: CircleAngle { directionA.opposite }
    public var pointAndDirectionA: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionA)
    }
    public var pointAndDirectionB: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionB)
    }

    public func orientation(inDirection direction: Direction) -> Angle {
        switch direction {
        case .a: directionA.asAngle
        case .b: directionB.asAngle
        }
    }

    public func offsetLeft(by d: Distance, alongDirection direction: Direction = .a) -> Point {
        point + d ** (orientation(inDirection: direction) + 90.0.deg)
    }

    public func offsetRight(by d: Distance, alongDirection direction: Direction = .a) -> Point {
        offsetLeft(by: -d, alongDirection: direction)
    }

    public internal(set) var directionATracks: [Track] = []
    public internal(set) var directionBTracks: [Track] = []
    public var allTracks: [Track] {
        directionATracks
            + directionBTracks.filter { bTrack in
                !directionATracks.contains { aTrack in
                    aTrack === bTrack
                }
            }
    }

    public func tracks(inDirection direction: Direction) -> [Track] {
        switch direction {
        case .a: directionATracks
        case .b: directionBTracks
        }
    }

    public var directionAStraightTrack: Track? {
        directionATracks.first {
            ($0.startConnection === self && $0.atomicPathTypeAtStart == .linear)
                || ($0.endConnection === self && $0.atomicPathTypeAtEnd == .linear)
        }
    }
    public var directionBStraightTrack: Track? {
        directionBTracks.first {
            ($0.startConnection === self && $0.atomicPathTypeAtStart == .linear)
                || ($0.endConnection === self && $0.atomicPathTypeAtEnd == .linear)
        }
    }

    internal func add(track: Track) {
        assert(track.path.start == point || track.path.end == point)
        if track.path.startPointAndOrientation == pointAndDirectionA
            || track.path.endPointAndOrientation == pointAndDirectionB
        {
            directionATracks.append(track)
            observers.forEach { $0.added(track: track, toConnection: self, inDirection: .a) }
        }
        if track.path.startPointAndOrientation == pointAndDirectionB
            || track.path.endPointAndOrientation == pointAndDirectionA
        {
            directionBTracks.append(track)
            observers.forEach { $0.added(track: track, toConnection: self, inDirection: .b) }
        }
    }

    internal func replace(oldTrack: Track, newTrack: Track) {
        if directionATracks.contains(where: { $0 === oldTrack }) {
            directionATracks.removeAll { $0 === oldTrack }
            directionATracks.append(newTrack)
            observers.forEach {
                $0.replaced(
                    track: oldTrack, withTrack: newTrack, inConnection: self, inDirection: .a)
            }
        }
        if directionBTracks.contains(where: { $0 === oldTrack }) {
            directionBTracks.removeAll { $0 === oldTrack }
            directionBTracks.append(newTrack)
            observers.forEach {
                $0.replaced(
                    track: oldTrack, withTrack: newTrack, inConnection: self, inDirection: .b)
            }
        }
    }

    internal func remove(track: Track) {
        directionATracks.removeAll { $0 === track }
        directionBTracks.removeAll { $0 === track }
        observers.forEach { $0.removed(track: track, fromConnection: self) }
    }

    internal func informObserversOfRemoval() {
        observers.forEach { $0.removed(connection: self) }
    }

    internal init(id: ID<TrackConnection>, point: Point, directionA: CircleAngle) {
        self.id = id
        self.point = point
        self.directionA = directionA
    }

    deinit {
        observers = []
    }

}
