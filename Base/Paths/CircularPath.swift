//
//  CircularPath.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

public struct CircularPath: FinitePath {
    public let center: Point
    public let radius: Distance
    public let circleRange: CircleRange

    private func toOrientation(_ a: CircleAngle) -> CircleAngle {
        switch circleRange.direction {
        case .positive: CircleAngle(a + 90.0.deg)
        case .negative: CircleAngle(a - 90.0.deg)
        }
    }

    public var start: Point { center + radius ** circleRange.startAngle }
    public var end: Point { center + radius ** circleRange.endAngle }
    public var startOrientation: CircleAngle { toOrientation(circleRange.start) }
    public var endOrientation: CircleAngle { toOrientation(circleRange.end) }
    public var length: Distance { radius * circleRange.absDelta }
    public var range: ClosedRange<Position> { Position(0.0)...length }
    public var reverse: CircularPath {
        CircularPath(center: center, radius: radius, circleRange: circleRange.flipped)!
    }
    public var finitePathType: FinitePathType { .circular }

    public func offsetLeft(by d: Distance) -> CircularPath? {
        let offsetRadius: Distance
        switch circleRange.direction {
        case .positive: offsetRadius = radius - d
        case .negative: offsetRadius = radius + d
        }
        return CircularPath(center: center, radius: offsetRadius, circleRange: circleRange)
    }

    public func toCircleAngle(_ x: Position) -> CircleAngle {
        CircleAngle(circleRange.start + circleRange.delta * (x / length))
    }

    private func toOrientation(_ x: Position) -> CircleAngle { toOrientation(toCircleAngle(x)) }

    private func toPosition(_ a: CircleAngle) -> Position {
        circleRange.fraction(for: a) * length
    }

    public func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return center + radius ** toCircleAngle(x).asAngle
    }

    public func orientation(at x: Position) -> CircleAngle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return toOrientation(x)
    }

    public func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m <= x && x < length { .circular } else { nil }
    }
    public func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m < x && x <= length { .circular } else { nil }
    }

    public func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        let circleAngle = CircleAngle(angle(from: center, to: p))
        if circleRange.contains(circleAngle) {
            return ClosestPathPointInfo(
                distance: abs(distance(p, center) - radius), x: toPosition(circleAngle),
                atomicPathInfo: .singleAtomicPath(.circular), specialCase: .no)
        }
        let distToStart = distance(p, start)
        let distToEnd = distance(p, end)
        return distToStart < distToEnd
            ? ClosestPathPointInfo(
                distance: distToStart, x: 0.0.m, atomicPathInfo: .singleAtomicPath(.circular),
                specialCase: .start)
            : ClosestPathPointInfo(
                distance: distToEnd, x: length, atomicPathInfo: .singleAtomicPath(.circular),
                specialCase: .end)
    }

    public func pointsOnPath(atDistance distToPoints: Distance, from p: Point) -> [Position] {
        let distToCenter = distance(center, p)
        if distToCenter < abs(radius - distToPoints) || distToCenter > radius + distToPoints {
            return []
        }
        let baseAngle = CircleAngle(angle(from: center, to: p))
        if distToCenter == abs(radius - distToPoints) || distToCenter == radius + distToPoints {
            return circleRange.contains(baseAngle) ? [toPosition(baseAngle)] : []
        }
        let l = (pow²(radius) + pow²(distToCenter) - pow²(distToPoints)) / (2.0 * distToCenter)
        let angleOffset = Angle(acos(l / radius))
        let angle1 = CircleAngle(baseAngle - angleOffset)
        let angle2 = CircleAngle(baseAngle + angleOffset)
        return [angle1, angle2].filter { circleRange.contains($0) }.map { toPosition($0) }.sorted()
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
        if !Rect.intersect(Rect.square(around: center, length: 2.0 * radius), rect) {
            return []
        } else if rect.contains(Rect.square(around: center, length: 2.0 * radius)) {
            return [0.0.m...length]
        } else {
            let xs: [Position] =
                (rect.lines.flatMap { side -> [Distance] in
                    side.argsForPoints(
                        atDistance: radius,
                        from: center
                    ).compactMap { x -> Distance? in
                        let p = side.point(at: x)
                        let a = CircleAngle(angle(from: center, to: p))
                        guard circleRange.contains(a) && rect.contains(p) else {
                            return nil
                        }
                        return toPosition(a)
                    }
                } + (rect.contains(start) ? [0.0.m] : []) + (rect.contains(end) ? [length] : []))
                .sorted().reduce([]) { list, x in
                    (list.last == x) ? list : list + [x]
                }
            assert(xs.count % 2 == 0, "Expected even number of xs")
            var segments: [ClosedRange<Position>] = []
            for i in 0..<xs.count / 2 {
                let x1 = xs[2 * i]
                let x2 = xs[2 * i + 1]
                segments.append(x1...x2)
            }
            return segments
        }
    }

    public func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if !range.contains(x) {
            return nil
        }
        if let (splitCircleRange1, splitCircleRange2) = circleRange.split(at: toCircleAngle(x)) {
            return (
                .circular(
                    CircularPath(center: center, radius: radius, circleRange: splitCircleRange1)!),
                .circular(
                    CircularPath(center: center, radius: radius, circleRange: splitCircleRange2)!)
            )
        } else {
            return nil
        }
    }

    public static func combine(_ a: CircularPath, _ b: CircularPath) -> CircularPath? {
        guard let circleRange = CircleRange.combine(a.circleRange, b.circleRange),
            a.center == b.center, a.radius == b.radius
        else {
            return nil
        }
        return CircularPath(center: a.center, radius: a.radius, circleRange: circleRange)
    }

    public static func isDistance(
        between a: CircularPath,
        and b: CircularPath,
        above requiredMinDistance: Distance
    ) -> Bool {
        let d = distance(a.center, b.center)
        if d - a.radius - b.radius > requiredMinDistance {
            return true
        }
        let p1 = a.point(at: a.closestPointOnPath(from: b.center).x)!
        let d1 = b.closestPointOnPath(from: p1).distance
        let p2 = b.point(at: b.closestPointOnPath(from: a.center).x)!
        let d2 = a.closestPointOnPath(from: p2).distance
        let actualMinDistance = min(d1, d2)
        return actualMinDistance > requiredMinDistance
    }

    public init?(
        center: Point, radius: Distance, circleRange: CircleRange
    ) {
        if radius * circleRange.absDelta < 1e-6.m {
            return nil
        }
        self.center = center
        self.radius = radius
        self.circleRange = circleRange
    }

    public init?(center: Point, radius: Distance, startAngle: CircleAngle, deltaAngle: AngleDiff) {
        self.init(
            center: center, radius: radius,
            circleRange: CircleRange(start: startAngle, delta: deltaAngle))
    }

    public init?(
        center: Point, radius: Distance, startAngle: CircleAngle, endAngle: CircleAngle,
        direction: CircleRange.Direction
    ) {
        self.init(
            center: center, radius: radius,
            circleRange: CircleRange(start: startAngle, end: endAngle, direction: direction))
    }

}
