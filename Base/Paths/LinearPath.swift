//
//  LinearPath.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

public struct LinearPath: FinitePath {
    public let start: Point
    public let end: Point
    public var orientation: CircleAngle { CircleAngle(angle(from: start, to: end)) }
    public var startOrientation: CircleAngle { orientation }
    public var endOrientation: CircleAngle { orientation }
    public var direction: Direction { Base.direction(from: start, to: end) }
    public var normDirection: NormDirection { NormDirection(direction)! }
    public var length: Distance { distance(start, end) }
    public var range: ClosedRange<Position> { Position(0.0)...length }
    public var reverse: LinearPath { LinearPath(start: end, end: start)! }
    public var finitePathType: FinitePathType { .linear }

    public var left: Angle { orientation + 90.0.deg }
    public var right: Angle { orientation - 90.0.deg }

    public func offsetLeft(by d: Distance) -> LinearPath? {
        LinearPath(start: start + d ** left, end: end + d ** left)!
    }

    public func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        let progress = x / length
        return start + (end - start) * progress
    }

    public func orientation(at x: Position) -> CircleAngle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return orientation
    }

    public func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m <= x && x < length { .linear } else { nil }
    }
    public func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m < x && x <= length { .linear } else { nil }
    }

    public func closestPointOnPath(from target: Point) -> ClosestPathPointInfo {
        let deltaDirection = Base.direction(from: start, to: target)
        let projectedDist = scalar(deltaDirection, direction) / length
        if range.contains(projectedDist) {
            let projectedPoint = start + (projectedDist * normDirection)
            let distToProjectedPoint = distance(target, projectedPoint)
            return ClosestPathPointInfo(
                distance: distToProjectedPoint, x: projectedDist,
                atomicPathInfo: .singleAtomicPath(.linear), specialCase: .no)
        }
        let distToStart = distance(target, start)
        let distToEnd = distance(target, end)
        if distToStart < distToEnd {
            return ClosestPathPointInfo(
                distance: distToStart, x: 0.0.m, atomicPathInfo: .singleAtomicPath(.linear),
                specialCase: .start)
        } else {
            return ClosestPathPointInfo(
                distance: distToEnd, x: length, atomicPathInfo: .singleAtomicPath(.linear),
                specialCase: .end)
        }
    }

    public func pointsOnPath(atDistance r: Distance, from: Point) -> [Position] {
        let a = distance²(start, end)
        let b =
            2.0
            * scalar(
                Base.direction(from: start, to: end),
                Base.direction(from: from, to: start))
        let c = distance²(start, from) - pow²(r)
        let d = pow²(b) - 4.0 * a * c
        if d < Distance⁴(0.0) {
            return []
        } else if d == Distance⁴(0.0) {
            let x = 0.5 * -b / length
            return [x].filter { range.contains($0) }
        } else {
            let x1 = 0.5 * (-b - sqrt(d)) / length
            let x2 = 0.5 * (-b + sqrt(d)) / length
            return [x1, x2].filter { range.contains($0) }
        }
    }

    public func firstPointOnPath(
        atDistance d: Distance, after min: Position
    ) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: min)!).filter { min <= $0 }.first
    }

    public func lastPointOnPath(
        atDistance d: Distance, before max: Position
    ) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: max)!).filter { $0 <= max }.last
    }

    public func segments(inRect rect: Rect) -> [ClosedRange<Position>] {
        if start.x < rect.minX && end.x < rect.minX {
            return []
        } else if start.x > rect.maxX && end.x > rect.maxX {
            return []
        } else if start.y < rect.minY && end.y < rect.minY {
            return []
        } else if start.y > rect.maxY && end.y > rect.maxY {
            return []
        } else if rect.contains(start) && rect.contains(end) {
            return [0.0.m...length]
        } else if start.x == end.x {
            return if start.y < end.y {
                [max(0.0.m, rect.minY - start.y)...min(length, rect.maxY - start.y)]
            } else {
                [max(0.0.m, start.y - rect.maxY)...min(length, start.y - rect.minY)]
            }
        } else if start.y == end.y {
            return if start.x < end.x {
                [max(0.0.m, rect.minX - start.x)...min(length, rect.maxX - start.x)]
            } else {
                [max(0.0.m, start.x - rect.maxX)...min(length, start.x - rect.minX)]
            }
        } else {
            let line = Line(through: start, and: end)!
            let xs = rect.lines.compactMap { side -> Distance? in
                guard let (r, s) = Line.argsForIntersection(side, line) else { return nil }
                guard 0.0.m <= s, s <= length, 0.0.m <= r, rect.contains(side.point(at: r)) else {
                    return nil
                }
                return s
            }
            if xs.count == 0 {
                return []
            } else if xs.count == 1 {
                if rect.contains(start) {
                    return [0.0.m...xs[0]]
                } else if rect.contains(end) {
                    return [xs[0]...length]
                }
            } else if xs.count == 2 {
                return [min(xs)...max(xs)]
            }
            assertionFailure("unexpected number of xs")
            return [0.0.m...length]
        }
    }

    public func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if x <= 0.0.m || x >= length {
            return nil
        }
        let p = point(at: x)!
        return (
            .linear(LinearPath(start: start, end: p)!), .linear(LinearPath(start: p, end: end)!)
        )
    }

    public static func combine(_ a: LinearPath, _ b: LinearPath) -> LinearPath? {
        guard canConnect(a.endPointAndOrientation, b.startPointAndOrientation) else {
            return nil
        }
        return LinearPath(start: a.start, end: b.end)!
    }

    public static func isDistance(
        between pathA: LinearPath,
        and pathB: LinearPath,
        above requiredMinDistance: Distance
    ) -> Bool {
        let lineA = Line(through: pathA.start, and: pathA.end)!
        let lineB = Line(through: pathB.start, and: pathB.end)!
        if let (argA, argB) = Line.argsForIntersection(lineA, lineB) {
            let onPathA = 0.0.m <= argA && argA <= pathA.length
            let onPathB = 0.0.m <= argB && argB <= pathB.length
            if onPathA && onPathB {
                return false
            }
        } else {
            let distanceBetweenLines = lineA.distance(to: lineB.base)
            if distanceBetweenLines > requiredMinDistance {
                return true
            }
        }
        let actualMinDistance = min([
            pathA.closestPointOnPath(from: pathB.start).distance,
            pathA.closestPointOnPath(from: pathB.end).distance,
            pathB.closestPointOnPath(from: pathA.start).distance,
            pathB.closestPointOnPath(from: pathA.end).distance,
        ])
        return actualMinDistance > requiredMinDistance
    }

    public init?(start: Point, end: Point) {
        if start == end {
            return nil
        }
        self.start = start
        self.end = end
    }

}
