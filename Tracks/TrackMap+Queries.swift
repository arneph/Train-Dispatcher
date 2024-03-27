//
//  TrackUtils.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 2/11/24.
//

import Base
import Foundation

public enum TrackPoint {
    case trackConnection(TrackConnection)
    case trackPoint(Track, Position)

    public var point: Point {
        switch self {
        case .trackConnection(let connection): connection.point
        case .trackPoint(let track, let x): track.path.point(at: x)!
        }
    }
    public var directionA: CircleAngle {
        switch self {
        case .trackConnection(let connection): connection.directionA
        case .trackPoint(let track, let x): track.path.orientation(at: x)!
        }
    }
    public var directionB: CircleAngle {
        switch self {
        case .trackConnection(let connection): connection.directionB
        case .trackPoint(let track, let x): track.path.orientation(at: x)!.opposite
        }
    }
    public var pointAndDirectionA: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionA)
    }
    public var pointAndDirectionB: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionB)
    }

    public func offsetLeft(by d: Distance) -> Point {
        switch self {
        case .trackConnection(let connection):
            connection.offsetLeft(by: d)
        case .trackPoint(let track, let x):
            track.path.point(at: x)! + d ** (track.path.orientation(at: x)! + 90.0.deg)
        }
    }

    public func offsetRight(by d: Distance) -> Point { offsetLeft(by: -d) }

    public var isTrackStart: Bool {
        switch self {
        case .trackConnection: true
        case .trackPoint(_, let x): x == 0.0.m
        }
    }
    public var isTrackEnd: Bool {
        switch self {
        case .trackConnection: true
        case .trackPoint(let track, let x): x == track.path.length
        }
    }

    public var isStraighInDirectionA: Bool {
        switch self {
        case .trackConnection(let connection): connection.directionAStraightTrack != nil
        case .trackPoint(let track, let x): track.path.forwardAtomicPathType(at: x) == .linear
        }
    }

    public var isStraightInDirectionB: Bool {
        switch self {
        case .trackConnection(let connection): connection.directionBStraightTrack != nil
        case .trackPoint(let track, let x): track.path.backwardAtomicPathType(at: x) == .linear
        }
    }

}

public struct ClosestTrackPointInfo {
    public let distance: Distance
    public let track: Track
    public var trackPath: SomeFinitePath { track.path }
    public let trackPathPosition: Position

    public let atomicPath: AtomicFinitePath
    public let atomicPathPosition: Position

    public let point: Point
    public let orientation: CircleAngle
    public var pointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: point, orientation: orientation)
    }

    public var isTrackStart: Bool { trackPathPosition == 0.0.m }
    public var isTrackEnd: Bool { trackPathPosition == track.path.length }
    public var connection: TrackConnection? {
        if isTrackStart {
            track.startConnection
        } else if isTrackEnd {
            track.endConnection
        } else {
            nil
        }
    }

    public var asTrackPoint: TrackPoint {
        if let connection {
            .trackConnection(connection)
        } else {
            .trackPoint(track, trackPathPosition)
        }
    }

    public init(distance: Distance, track: Track, trackPathPosition: Position) {
        self.distance = distance
        self.track = track
        self.trackPathPosition = trackPathPosition

        switch self.track.path {
        case .linear(let path):
            self.atomicPath = .linear(path)
            self.atomicPathPosition = self.trackPathPosition
        case .circular(let path):
            self.atomicPath = .circular(path)
            self.atomicPathPosition = self.trackPathPosition
        case .compound(let path):
            (self.atomicPath, self.atomicPathPosition) = path.component(at: self.trackPathPosition)!
        }
        self.point = atomicPath.point(at: atomicPathPosition)!
        self.orientation = atomicPath.orientation(at: atomicPathPosition)!
    }
}

extension TrackMap {

    public func closestPointOnTrack(from point: Point) -> ClosestTrackPointInfo? {
        var closest: ClosestTrackPointInfo?
        for track in tracks {
            let candidate = track.path.closestPointOnPath(from: point)
            if let closest = closest, candidate.distance > closest.distance {
                continue
            }
            closest = ClosestTrackPointInfo(
                distance: candidate.distance, track: track, trackPathPosition: candidate.x)
        }
        return closest
    }

    public var pointsOfInterest: [TrackPoint] {
        connections.map { .trackConnection($0) }
            + tracks.flatMap { $0.startConnection == nil ? [.trackPoint($0, 0.0.m)] : [] }
            + tracks.flatMap { $0.endConnection == nil ? [.trackPoint($0, $0.path.length)] : [] }
            + tracks.flatMap { (track) -> [TrackPoint] in
                switch track.path {
                case .compound(let path):
                    path.componentSplitPositions.map { .trackPoint(track, $0) }
                default: []
                }
            }
    }

}
