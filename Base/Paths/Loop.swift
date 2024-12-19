//
//  Loop.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

public struct Loop: Path {
    public let underlying: SomeFinitePath
    public var start: Point { underlying.start }
    public var end: Point { underlying.end }
    public var startOrientation: CircleAngle { underlying.startOrientation }
    public var endOrientation: CircleAngle { underlying.endOrientation }
    public var length: Distance { Distance(Float64.infinity) }
    public var range: ClosedRange<Position> {
        Position(-Float64.infinity)...Position(Float64.infinity)
    }
    public var reverse: Loop { Loop(underlying: underlying.reverse)! }

    public func offsetLeft(by d: Distance) -> Loop? {
        guard let offsetUnderlying = underlying.offsetLeft(by: d) else {
            return nil
        }
        return Loop(underlying: offsetUnderlying)
    }

    public func normalize(_ x: Position) -> Position {
        normalizeWithDelta(x).normalized
    }

    private func normalizeWithDelta(_ x: Position) -> (
        normalized: Position, delta: Distance
    ) {
        var delta = 0.0.m
        while x + delta < 0.0.m {
            delta += underlying.length
        }
        while x + delta >= underlying.length {
            delta -= underlying.length
        }
        return (x + delta, delta)
    }

    public func point(at x: Position) -> Point? {
        underlying.point(at: normalize(x))
    }

    public func orientation(at x: Position) -> CircleAngle? {
        underlying.orientation(at: normalize(x))
    }

    public func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        underlying.forwardAtomicPathType(at: normalize(x))
    }

    public func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        let normalizedX = normalize(x)
        if normalizedX == 0.0.m {
            return underlying.backwardAtomicPathType(at: underlying.length)
        } else {
            return underlying.backwardAtomicPathType(at: normalizedX)
        }
    }

    public func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        underlying.closestPointOnPath(from: p)
    }

    public func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        underlying.pointsOnPath(atDistance: d, from: p)
    }

    public func firstPointOnPath(
        atDistance d: Distance, after minGlobal: Position
    ) -> Position? {
        let (x, delta) = normalizeWithDelta(minGlobal)
        if let result = underlying.firstPointOnPath(atDistance: d, after: x) {
            return result - delta
        } else if let result = underlying.pointsOnPath(
            atDistance: d, from: underlying.point(at: x)!
        ).first {
            return result - delta + underlying.length
        } else {
            return nil
        }
    }

    public func lastPointOnPath(atDistance d: Distance, before maxGlobal: Position) -> Position? {
        let (x, delta) = normalizeWithDelta(maxGlobal)
        if let result = underlying.lastPointOnPath(atDistance: d, before: x) {
            return result - delta
        } else if let result = underlying.pointsOnPath(
            atDistance: d, from: underlying.point(at: x)!
        ).last {
            return result - delta - underlying.length
        } else {
            return nil
        }
    }

    public static func isDistance(between a: Loop, and b: Loop, above minDistance: Distance)
        -> Bool
    {
        SomeFinitePath.isDistance(
            between: a.underlying, and: b.underlying, above: minDistance)
    }

    init?(underlying: SomeFinitePath) {
        if canConnect(underlying.startPointAndOrientation, underlying.endPointAndOrientation) {
            return nil
        }
        self.underlying = underlying
    }

}
