//
//  TrackUtils.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 2/11/24.
//

import Foundation

enum TrackPoint {
    case trackConnection(TrackConnection)
    case trackPoint(Track, Position)
    
    var point: Point {
        switch self {
        case .trackConnection(let connection): connection.point
        case .trackPoint(let track, let x): track.path.point(at: x)!
        }
    }
    var directionA: CircleAngle {
        switch self {
        case .trackConnection(let connection): connection.directionA
        case .trackPoint(let track, let x): track.path.orientation(at: x)!
        }
    }
    var directionB: CircleAngle {
        switch self {
        case .trackConnection(let connection): connection.directionB
        case .trackPoint(let track, let x): track.path.orientation(at: x)!.opposite
        }
    }
    var pointAndDirectionA: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionA)
    }
    var pointAndDirectionB: PointAndOrientation {
        PointAndOrientation(point: point, orientation: directionB)
    }
    
    func offsetLeft(by d: Distance) -> Point {
        switch self {
        case .trackConnection(let connection):
            connection.offsetLeft(by: d)
        case .trackPoint(let track, let x):
            track.path.point(at: x)! + d ** (track.path.orientation(at: x)! + 90.0.deg)
        }
    }
    
    func offsetRight(by d: Distance) -> Point { offsetLeft(by: -d) }
    
    var isTrackStart: Bool {
        switch self {
        case .trackConnection: true
        case .trackPoint(_, let x): x == 0.0.m
        }
    }
    var isTrackEnd: Bool {
        switch self {
        case .trackConnection: true
        case .trackPoint(let track, let x): x == track.path.length
        }
    }
    
    var isStraighInDirectionA: Bool {
        switch self {
        case .trackConnection(let connection): connection.directionAStraightTrack != nil
        case .trackPoint(let track, let x): track.path.forwardAtomicPathType(at: x) == .linear
        }
    }
    
    var isStraightInDirectionB: Bool {
        switch self {
        case .trackConnection(let connection): connection.directionBStraightTrack != nil
        case .trackPoint(let track, let x): track.path.backwardAtomicPathType(at: x) == .linear
        }
    }
    
}

struct ClosestTrackPointInfo {
    let distance: Distance
    let track: Track
    var trackPath: SomeFinitePath { track.path }
    let trackPathPosition: Position

    let atomicPath: AtomicFinitePath
    let atomicPathPosition: Position
    
    let point: Point
    let orientation: CircleAngle
    var pointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: point, orientation: orientation)
    }
    
    var isTrackStart: Bool { trackPathPosition == 0.0.m }
    var isTrackEnd: Bool { trackPathPosition == track.path.length }
    var connection: TrackConnection? {
        if isTrackStart {
            track.startConnection
        } else if isTrackEnd {
            track.endConnection
        } else {
            nil
        }
    }
    
    var asTrackPoint: TrackPoint {
        if let connection {
            .trackConnection(connection)
        } else {
            .trackPoint(track, trackPathPosition)
        }
    }
    
    init(distance: Distance, track: Track, trackPathPosition: Position) {
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
    
    func closestPointOnTrack(from point: Point) -> ClosestTrackPointInfo? {
        var closest: ClosestTrackPointInfo?
        for track in tracks {
            let candidate = track.path.closestPointOnPath(from: point)
            if let closest = closest, candidate.distance > closest.distance {
                continue
            }
            closest = ClosestTrackPointInfo(distance: candidate.distance,
                                            track: track,
                                            trackPathPosition: candidate.x)
        }
        return closest
    }
    
    var pointsOfInterest: [TrackPoint] {
        connections.map{ .trackConnection($0) } +
        tracks.flatMap{ $0.startConnection == nil ? [.trackPoint($0, 0.0.m)] : [] } +
        tracks.flatMap{ $0.endConnection == nil ? [.trackPoint($0, $0.path.length)] : [] } +
        tracks.flatMap{ (track) -> [TrackPoint] in
            switch track.path {
            case .compound(let path):
                path.componentSplitPositions.map{ .trackPoint(track, $0) }
            default: []
            }
        }
    }
    
}
