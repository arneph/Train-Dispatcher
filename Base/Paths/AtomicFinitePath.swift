//
//  AtomicFinitePath.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

public enum AtomicFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)

    public var start: Point {
        switch self {
        case .linear(let path): path.start
        case .circular(let path): path.start
        }
    }
    public var end: Point {
        switch self {
        case .linear(let path): path.end
        case .circular(let path): path.end
        }
    }
    public var startOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.startOrientation
        case .circular(let path): path.startOrientation
        }
    }
    public var endOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.endOrientation
        case .circular(let path): path.endOrientation
        }
    }
    public var length: Distance {
        switch self {
        case .linear(let path): path.length
        case .circular(let path): path.length
        }
    }
    public var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): path.range
        case .circular(let path): path.range
        }
    }
    public var reverse: AtomicFinitePath {
        switch self {
        case .linear(let path): .linear(path.reverse)
        case .circular(let path): .circular(path.reverse)
        }
    }
    public var finitePathType: FinitePathType {
        switch self {
        case .linear: .linear
        case .circular: .circular
        }
    }

    public func offsetLeft(by d: Distance) -> AtomicFinitePath? {
        switch self {
        case .linear(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                .linear(offsetPath)
            } else {
                nil
            }
        case .circular(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                .circular(offsetPath)
            } else {
                nil
            }
        }
    }

    public func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): path.point(at: x)
        case .circular(let path): path.point(at: x)
        }
    }

    public func orientation(at x: Position) -> CircleAngle? {
        switch self {
        case .linear(let path): path.orientation(at: x)
        case .circular(let path): path.orientation(at: x)
        }
    }

    public func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.forwardAtomicPathType(at: x)
        case .circular(let path): path.forwardAtomicPathType(at: x)
        }
    }
    public func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.backwardAtomicPathType(at: x)
        case .circular(let path): path.backwardAtomicPathType(at: x)
        }
    }

    public func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): path.closestPointOnPath(from: p)
        case .circular(let path): path.closestPointOnPath(from: p)
        }
    }

    public func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): path.pointsOnPath(atDistance: d, from: p)
        }
    }

    public func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): path.firstPointOnPath(atDistance: d, after: x)
        }
    }

    public func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): path.lastPointOnPath(atDistance: d, before: x)
        }
    }

    public func segments(inRect rect: Rect) -> [ClosedRange<Position>] {
        switch self {
        case .linear(let path): path.segments(inRect: rect)
        case .circular(let path): path.segments(inRect: rect)
        }
    }

    public func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): path.split(at: x)
        case .circular(let path): path.split(at: x)
        }
    }

    public static func combine(_ a: AtomicFinitePath, _ b: AtomicFinitePath) -> AtomicFinitePath? {
        switch (a, b) {
        case (.linear(let a), .linear(let b)):
            if let path = LinearPath.combine(a, b) {
                .linear(path)
            } else {
                nil
            }
        case (.circular(let a), .circular(let b)):
            if let path = CircularPath.combine(a, b) {
                .circular(path)
            } else {
                nil
            }
        case (.linear, .circular), (.circular, .linear):
            nil
        }
    }

    public static func isDistance(
        between a: AtomicFinitePath,
        and b: AtomicFinitePath,
        above minDistance: Distance
    ) -> Bool {
        switch (a, b) {
        case (.linear(let a), .linear(let b)):
            LinearPath.isDistance(between: a, and: b, above: minDistance)
        case (.circular(let a), .circular(let b)):
            CircularPath.isDistance(between: a, and: b, above: minDistance)
        case (.linear(let a), .circular(let b)):
            AtomicFinitePath.isDistance(between: a, and: b, alwaysAbove: minDistance)
        case (.circular(let a), .linear(let b)):
            AtomicFinitePath.isDistance(between: b, and: a, alwaysAbove: minDistance)
        }
    }

    internal static func isDistance(
        between pathA: LinearPath,
        and pathB: CircularPath,
        alwaysAbove requiredMinDistance: Distance
    ) -> Bool {
        let p = pathA.point(at: pathA.closestPointOnPath(from: pathB.center).x)!
        let d = pathB.closestPointOnPath(from: p).distance
        let actualMinDistance = min([
            d,
            pathA.closestPointOnPath(from: pathB.start).distance,
            pathA.closestPointOnPath(from: pathB.end).distance,
            pathB.closestPointOnPath(from: pathA.start).distance,
            pathB.closestPointOnPath(from: pathA.end).distance,
        ])
        return actualMinDistance > requiredMinDistance
    }

}
