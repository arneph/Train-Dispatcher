//
//  TrackPen.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/14/24.
//

import Foundation

enum DragPoint {
    case freePoint(Point)
    case trackMidPoint(ClosestTrackPointInfo)
    case trackEndPoint(ClosestTrackPointInfo)
    
    var point: Point {
        switch self {
        case .freePoint(let point):
            return point
        case .trackMidPoint(let info):
            return info.point
        case .trackEndPoint(let info):
            return info.point
        }
    }
}

func dragStartPointFor(map: Map, point: Point) -> DragPoint {
    if let closestTrackPointInfo = map.closestPointOnTrack(from: point),
        closestTrackPointInfo.distance <= 5.0.m {
        if closestTrackPointInfo.isTrackStart || closestTrackPointInfo.isTrackEnd {
            return .trackEndPoint(closestTrackPointInfo)
        } else {
            return .trackMidPoint(closestTrackPointInfo)
        }
    }
    return .freePoint(point)
}

func dragEndPointFor(map: Map, point: Point, startPoint: DragPoint) -> DragPoint {
    if let closestTrackPointInfo = map.closestPointOnTrack(from: point),
        closestTrackPointInfo.distance <= 5.0.m {
        if closestTrackPointInfo.isTrackStart || closestTrackPointInfo.isTrackEnd {
            return .trackEndPoint(closestTrackPointInfo)
        } else {
            return .trackMidPoint(closestTrackPointInfo)
        }
    }
    switch startPoint {
    case .trackEndPoint(let start):
        let p = closestPointOnLine(through: start.point,
                                   withOrientation: start.orientation,
                                   to: point)
        if distance(point, p) <= 5.0.m {
            return .freePoint(p)
        }
        break
    default:
        break
    }
    return .freePoint(point)
}

func trackForDrag(from start: DragPoint, to end: DragPoint) -> Track? {
    switch (start, end) {
    case (.freePoint(let start), .freePoint(let end)):
        guard let path = LinearPath(start: start, end: end) else { return nil }
        return Track(path: .linear(path))
    case (.freePoint(let start), .trackMidPoint(let end)):
        if let path = circularPath(fromTrackPoint: end, toFreePoint: start) {
            return Track(path: .circular(path.reverse))
        }
        return nil
    case (.trackMidPoint(let start), .freePoint(let end)):
        if let path = circularPath(fromTrackPoint: start, toFreePoint: end) {
            return Track(path: .circular(path))
        }
        return nil
    case (.trackEndPoint(let start), .freePoint(let end)):
        if let path = linearPath(fromTrackPoint: start, toFreePoint: end) {
            return Track(path: .linear(path))
        } else if let path = circularPath(fromTrackPoint: start, toFreePoint: end) {
            return Track(path: .circular(path))
        }
        return nil
    default:
        return nil
    }
}

fileprivate func linearPath(fromTrackPoint start: ClosestTrackPointInfo, 
                            toFreePoint end: Point) -> LinearPath? {
    guard let path = LinearPath(start: start.point, end: end),
          canConnect(start.pointAndOrientation, path.startPointAndOrientation) else {
        return nil
    }
    return path
}

fileprivate func circularPath(fromTrackPoint start: ClosestTrackPointInfo,
                              toFreePoint end: Point) -> CircularPath? {
    var orientation = start.orientation
    var alpha = clamp(angle: angle(from: start.point, to: end) - start.orientation,
                      min: -180.0.deg)
    if alpha < -90.0.deg {
        orientation += 180.0.deg
        alpha += 180.0.deg
    } else if alpha > 90.0.deg {
        orientation += 180.0.deg
        alpha -= 180.0.deg
    }
    let dist = distance(start.point, end)
    let radius = dist / 2.0 / sin(alpha)
    let center = start.point + (orientation + 90.0.deg) ** radius
    return CircularPath(center: center,
                        radius: abs(radius),
                        startAngle: angle(from: center, to: start.point),
                        endAngle: angle(from: center, to: end),
                        clockwise: alpha < 0.0.deg)
}
