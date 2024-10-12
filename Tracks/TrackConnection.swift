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

    internal private(set) var observers: [TrackConnectionObserver] = []
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

    public var hasSwitchInDirectionA: Bool { directionATracks.count > 1 }
    public var hasSwitchInDirectionB: Bool { directionBTracks.count > 1 }

    public func hasSwitch(inDirection direction: Direction) -> Bool {
        switch direction {
        case .a: hasSwitchInDirectionA
        case .b: hasSwitchInDirectionB
        }
    }

    public struct StateChange {
        let previous: Track
        let next: Track
        let progress: Float64
    }
    public enum State {
        case fixed(Track)
        case changing(StateChange)

        public var activeTrack: Track? {
            switch self {
            case .fixed(let track): track
            case .changing(_): nil
            }
        }
    }

    public internal(set) var directionAState: State? = nil
    public internal(set) var directionBState: State? = nil

    public func state(inDirection direction: Direction) -> State? {
        switch direction {
        case .a: directionAState
        case .b: directionBState
        }
    }

    public var directionAActiveTrack: Track? { directionAState?.activeTrack ?? nil }
    public var directionBActiveTrack: Track? { directionBState?.activeTrack ?? nil }

    public func activeTrack(inDirection direction: Direction) -> Track? {
        switch direction {
        case .a: directionAActiveTrack
        case .b: directionBActiveTrack
        }
    }

    public func switchPath(for track: Track) -> SomeFinitePath {
        let maxLength = 50.0.m
        let length = min(track.path.length / 2.0, maxLength)
        return if track.startConnection === self {
            track.path.subPath(from: 0.0.m, to: length)!
        } else if track.endConnection === self {
            track.path.subPath(from: track.path.length - length, to: track.path.length)!
        } else {
            fatalError("Track does not end at connection.")
        }
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
