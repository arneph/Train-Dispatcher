//
//  Path.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/19/24.
//

import Foundation

private let minDistance = 0.001.m
private let minAngle = 0.001.deg

private let epsilon = Distance(1e-6)

private func isApproximatelyEqual(x: Position, y: Position) -> Bool { abs(x - y) < epsilon }
private func isApproximatelyLessThan(x: Position, y: Position) -> Bool { x - y < -epsilon }
private func isApproximatelyGreaterThan(x: Position, y: Position) -> Bool { x - y > +epsilon }

private func isApproximatelyInRange(
    x: Position, range: ClosedRange<Position>
) -> Bool {
    range.lowerBound <= x + epsilon && x - epsilon <= range.upperBound
}

public struct PointAndOrientation: Equatable, Hashable, Codable {
    public let point: Point
    public let orientation: CircleAngle

    public init(point: Point, orientation: CircleAngle) {
        self.point = point
        self.orientation = orientation
    }
}

public enum PathExtremity: Equatable, Hashable, Codable {
    case start, end

    public var opposite: PathExtremity {
        switch self {
        case .start: .end
        case .end: .start
        }
    }
}

public enum AtomicPathType: Equatable, Hashable, Codable {
    case linear, circular
}

public enum FinitePathType: Equatable, Hashable, Codable {
    case linear, circular, compound

    public var atomicPathType: AtomicPathType? {
        switch self {
        case .linear: .linear
        case .circular: .circular
        case .compound: nil
        }
    }

    public init(_ atomicPathType: AtomicPathType) {
        switch atomicPathType {
        case .linear: self = .linear
        case .circular: self = .circular
        }
    }
}

public struct ClosestPathPointInfo: Equatable, Hashable, Codable {
    public enum AtomicPathInfo: Equatable, Hashable, Codable {
        case singleAtomicPath(AtomicPathType)
        case twoAtomicPathsConnection(AtomicPathType, AtomicPathType)
    }
    public enum SpecialCase: Equatable, Hashable, Codable {
        case no, start, end
    }

    public let distance: Distance
    public let x: Position
    public let atomicPathInfo: AtomicPathInfo
    public let specialCase: SpecialCase
}

public protocol Path: Equatable, Hashable, Codable {
    var reverse: Self { get }

    func offsetLeft(by: Distance) -> Self?
    func offsetRight(by: Distance) -> Self?

    func normalize(_ x: Position) -> Position

    func point(at x: Position) -> Point?
    func orientation(at x: Position) -> CircleAngle?
    func pointAndOrientation(at x: Position) -> PointAndOrientation?

    func forwardAtomicPathType(at x: Position) -> AtomicPathType?
    func backwardAtomicPathType(at x: Position) -> AtomicPathType?

    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position]
}

extension Path {
    public func offsetRight(by d: Distance) -> Self? { offsetLeft(by: -d) }

    public func normalize(_ x: Position) -> Position { x }

    public func pointAndOrientation(at x: Position) -> PointAndOrientation? {
        guard let point = point(at: x), let orientation = orientation(at: x) else {
            return nil
        }
        return PointAndOrientation(point: point, orientation: orientation)
    }
}

public protocol FinitePath: Path {
    var start: Point { get }
    var end: Point { get }
    var startOrientation: CircleAngle { get }
    var endOrientation: CircleAngle { get }
    var length: Distance { get }
    var range: ClosedRange<Position> { get }

    var startPointAndOrientation: PointAndOrientation { get }
    var endPointAndOrientation: PointAndOrientation { get }

    var finitePathType: FinitePathType { get }

    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position?
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position?

    func segments(inRect: Rect) -> [ClosedRange<Position>]

    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)?
    static func combine(_ a: Self, _ b: Self) -> Self?
    static func combine(_ paths: [Self]) -> Self?
}

extension FinitePath {
    public var startPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: start, orientation: startOrientation)
    }
    public var endPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: end, orientation: endOrientation)
    }

    public static func combine(_ paths: [Self]) -> Self? {
        guard !paths.isEmpty else { return nil }
        var combined = paths.first!
        for path in paths.dropFirst() {
            guard let result = Self.combine(combined, path) else { return nil }
            combined = result
        }
        return combined
    }

    public func split(at x1: Position, and x2: Position) -> (
        SomeFinitePath, SomeFinitePath, SomeFinitePath
    )? {
        guard let (tmp, partC) = self.split(at: x2) else { return nil }
        guard let (partA, partB) = tmp.split(at: x1) else { return nil }
        return (partA, partB, partC)
    }

    public func subPath(from x1: Position, to x2: Position) -> SomeFinitePath? {
        guard 0.0.m <= x1 && x1 < x2 && x2 <= self.length else { return nil }
        return if x1 == 0.0.m && x2 == self.length {
            switch self.finitePathType {
            case .linear: .linear(self as! LinearPath)
            case .circular: .circular(self as! CircularPath)
            case .compound: .compound(self as! CompoundPath)
            }
        } else if x1 == 0.0.m {
            self.split(at: x2)!.0
        } else if x2 == self.length {
            self.split(at: x1)!.1
        } else {
            self.split(at: x1, and: x2)!.1
        }
    }
}

public func canConnect(_ a: PointAndOrientation, _ b: PointAndOrientation) -> Bool {
    distance(a.point, b.point) < minDistance && absDiff(a.orientation, b.orientation) <= minAngle
}

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

    public init?(start: Point, end: Point) {
        if start == end {
            return nil
        }
        self.start = start
        self.end = end
    }

}

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

}

public struct CompoundPath: FinitePath {
    private struct Context {
        let globalStart: Position
        let globalEnd: Position
        var globalRange: ClosedRange<Position> { globalStart...globalEnd }

        func toLocal(_ xGlobal: Position) -> Position { xGlobal - globalStart }
        func toGlobal(_ xLocal: Position) -> Position { globalStart + xLocal }
    }
    public let components: [AtomicFinitePath]
    private let contexts: [Context]

    public var componentSplitPositions: [Position] { contexts.dropFirst().map { $0.globalStart } }

    public var start: Point { components.first!.start }
    public var end: Point { components.last!.end }
    public var startOrientation: CircleAngle { components.first!.startOrientation }
    public var endOrientation: CircleAngle { components.last!.endOrientation }
    public var length: Distance { contexts.last!.globalEnd }
    public var range: ClosedRange<Position> { Position(0.0)...length }
    public var reverse: CompoundPath {
        CompoundPath(checkedComponents: components.map { $0.reverse }.reversed())
    }
    public var finitePathType: FinitePathType { .compound }

    public func offsetLeft(by d: Distance) -> CompoundPath? {
        let offsetAtomicFinitePaths = components.compactMap({ $0.offsetLeft(by: d) })
        guard offsetAtomicFinitePaths.count == components.count else {
            return nil
        }
        return CompoundPath(checkedComponents: offsetAtomicFinitePaths)
    }

    public func component(at xGlobal: Position) -> (component: AtomicFinitePath, xLocal: Position)?
    {
        guard let (_, component, xLocal) = indexAndAtomicFinitePath(at: xGlobal) else { return nil }
        return (component, xLocal)
    }

    private func indexAndAtomicFinitePath(at xGlobal: Position) -> (
        index: Int, component: AtomicFinitePath, xLocal: Position
    )? {
        if xGlobal < 0.0.m || length < xGlobal { return nil }
        var min = 0
        var max = components.count - 1
        var index = components.count / 2
        while true {
            if xGlobal < contexts[index].globalStart {
                max = index - 1
            } else if xGlobal > contexts[index].globalEnd {
                min = index + 1
            } else {
                return (index, components[index], contexts[index].toLocal(xGlobal))
            }
            index = (min + max) / 2
        }
    }

    public func point(at xGlobal: Position) -> Point? {
        guard let (component, xLocal) = component(at: xGlobal) else {
            return nil
        }
        return component.point(at: xLocal)
    }

    public func orientation(at xGlobal: Position) -> CircleAngle? {
        guard let (component, xLocal) = component(at: xGlobal) else {
            return nil
        }
        return component.orientation(at: xLocal)
    }

    public func forwardAtomicPathType(at xGlobal: Position) -> AtomicPathType? {
        guard let (index, component, xLocal) = indexAndAtomicFinitePath(at: xGlobal) else {
            return nil
        }
        if index < components.count - 1 && xLocal == component.length {
            return components[index + 1].forwardAtomicPathType(at: 0.0.m)
        } else {
            return component.forwardAtomicPathType(at: xLocal)
        }
    }

    public func backwardAtomicPathType(at xGlobal: Position) -> AtomicPathType? {
        guard let (index, component, xLocal) = indexAndAtomicFinitePath(at: xGlobal) else {
            return nil
        }
        if index > 0 && xLocal == 0.0.m {
            return components[index - 1].backwardAtomicPathType(at: components[index - 1].length)
        } else {
            return component.backwardAtomicPathType(at: xLocal)
        }
    }

    public func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        zip(components, contexts).enumerated().map {
            (
                index: Int, componentAndContext: (AtomicFinitePath, Context)
            ) -> ClosestPathPointInfo in
            let (component, context) = componentAndContext
            let localPoint = component.closestPointOnPath(from: p)
            let atomicPathInfo: ClosestPathPointInfo.AtomicPathInfo
            let specialCase: ClosestPathPointInfo.SpecialCase
            switch localPoint.specialCase {
            case .no:
                atomicPathInfo = localPoint.atomicPathInfo
                specialCase = .no
            case .start:
                if index == 0 {
                    atomicPathInfo = localPoint.atomicPathInfo
                    specialCase = .start
                } else {
                    atomicPathInfo = .twoAtomicPathsConnection(
                        components[index - 1].finitePathType.atomicPathType!,
                        component.finitePathType.atomicPathType!)
                    specialCase = .no
                }
            case .end:
                if index == components.count - 1 {
                    atomicPathInfo = localPoint.atomicPathInfo
                    specialCase = .end
                } else {
                    atomicPathInfo = .twoAtomicPathsConnection(
                        component.finitePathType.atomicPathType!,
                        components[index + 1].finitePathType.atomicPathType!)
                    specialCase = .no
                }
            }
            return ClosestPathPointInfo(
                distance: localPoint.distance, x: context.toGlobal(localPoint.x),
                atomicPathInfo: atomicPathInfo, specialCase: specialCase)
        }.min(by: { $0.distance < $1.distance })!
    }

    public func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        zip(components, contexts)
            .flatMap { (component: AtomicFinitePath, context: Context) -> [Position] in
                component.pointsOnPath(atDistance: d, from: p)
                    .map { context.toGlobal($0) }
            }
            .reduce([]) { xs, x in
                isApproximatelyEqual(x: xs.last ?? Position(-1.0), y: x)
                    ? xs : (xs + [x])
            }
    }

    public func firstPointOnPath(atDistance d: Distance, after minGlobal: Position) -> Position? {
        var p: Point? = nil
        for (component, context) in zip(components, contexts) {
            if isApproximatelyLessThan(x: context.globalEnd, y: minGlobal) {
                continue
            }
            let minLocal = context.toLocal(minGlobal)
            if p == nil {
                p = component.point(at: minLocal)
            }
            for xLocal in component.pointsOnPath(atDistance: d, from: p!) {
                if xLocal >= minLocal {
                    return context.toGlobal(xLocal)
                }
            }
        }
        return nil
    }

    public func lastPointOnPath(atDistance d: Distance, before maxGlobal: Position) -> Position? {
        var p: Point? = nil
        for (component, context) in zip(components, contexts).reversed() {
            if isApproximatelyGreaterThan(x: context.globalStart, y: maxGlobal) {
                continue
            }
            let maxLocal = context.toLocal(maxGlobal)
            if p == nil {
                p = component.point(at: maxLocal)
            }
            for xLocal in component.pointsOnPath(atDistance: d, from: p!) {
                if xLocal <= maxLocal {
                    return context.toGlobal(xLocal)
                }
            }
        }
        return nil
    }

    public func segments(inRect rect: Rect) -> [ClosedRange<Position>] {
        let segmentParts = zip(components, contexts).flatMap { (component, context) in
            let localSegments = component.segments(inRect: rect)
            let globalSegments = localSegments.map {
                context.toGlobal($0.lowerBound)...context.toGlobal($0.upperBound)
            }
            return globalSegments
        }
        var segments: [ClosedRange<Position>] = []
        var i = 0
        while i < segmentParts.count {
            let start = segmentParts[i].lowerBound
            var end = segmentParts[i].upperBound
            i += 1
            while i < segmentParts.count && segmentParts[i].lowerBound == end {
                end = segmentParts[i].upperBound
                i += 1
            }
            segments.append(start...end)
        }
        return segments
    }

    public func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if x <= 0.0.m || x >= length {
            return nil
        }
        guard let (index, component, xLocal) = indexAndAtomicFinitePath(at: x) else {
            return nil
        }
        let componentsA: [AtomicFinitePath]
        let componentsB: [AtomicFinitePath]
        if xLocal == 0.0.m {
            componentsA = Array(components.prefix(upTo: index))
            componentsB = Array(components.suffix(from: index))
        } else if xLocal == component.length {
            componentsA = Array(components.prefix(upTo: index + 1))
            componentsB = Array(components.suffix(from: index + 1))
        } else {
            let (a, b) = component.split(at: xLocal)!
            componentsA = components.prefix(upTo: index) + [a.atomic!]
            componentsB = [b.atomic!] + components.suffix(from: index + 1)
        }
        return (
            CompoundPath.combine(splitPaths: componentsA),
            CompoundPath.combine(splitPaths: componentsB)
        )
    }

    private static func combine(splitPaths paths: [AtomicFinitePath]) -> SomeFinitePath {
        if paths.count == 1 {
            SomeFinitePath(paths.first!)
        } else {
            .compound(CompoundPath(checkedComponents: paths))
        }
    }

    public static func combine(_ a: CompoundPath, _ b: CompoundPath) -> CompoundPath? {
        guard a.end == b.start, a.endOrientation == b.startOrientation else {
            return nil
        }
        let components: [AtomicFinitePath]
        if let combined = AtomicFinitePath.combine(a.components.last!, b.components.first!) {
            components = a.components.dropLast() + [combined] + b.components.dropFirst()
        } else {
            components = a.components + b.components
        }
        return CompoundPath(checkedComponents: components)
    }

    public static func combine(_ a: AtomicFinitePath, _ b: CompoundPath) -> CompoundPath? {
        guard canConnect(a.endPointAndOrientation, b.startPointAndOrientation) else {
            return nil
        }
        let components: [AtomicFinitePath]
        if let combined = AtomicFinitePath.combine(a, b.components.first!) {
            components = [combined] + b.components.dropFirst()
        } else {
            components = [a] + b.components
        }
        return CompoundPath(checkedComponents: components)
    }

    public static func combine(_ a: CompoundPath, _ b: AtomicFinitePath) -> CompoundPath? {
        guard canConnect(a.endPointAndOrientation, b.startPointAndOrientation) else {
            return nil
        }
        let components: [AtomicFinitePath]
        if let combined = AtomicFinitePath.combine(a.components.last!, b) {
            components = a.components.dropLast() + [combined]
        } else {
            components = a.components + [b]
        }
        return CompoundPath(checkedComponents: components)
    }

    public static func == (lhs: CompoundPath, rhs: CompoundPath) -> Bool {
        lhs.components == rhs.components
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(components)
    }

    public init?(components: [AtomicFinitePath]) {
        if components.count < 2 {
            return nil
        }
        for index in 0...components.count - 2 {
            guard components[index].end == components[index + 1].start,
                components[index].endOrientation == components[index + 1].startOrientation
            else {
                return nil
            }
        }
        self.init(checkedComponents: components)
    }

    private init(checkedComponents components: [AtomicFinitePath]) {
        self.components = components
        var x = 0.0.m
        self.contexts = components.map { (component) in
            let globalStart = x
            let globalEnd = x + component.length
            x = globalEnd
            return Context(globalStart: globalStart, globalEnd: globalEnd)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case components
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let components = try values.decode([AtomicFinitePath].self, forKey: .components)
        self.init(checkedComponents: components)
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(components, forKey: .components)
    }

}

public enum SomeFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)
    case compound(CompoundPath)

    public var start: Point {
        switch self {
        case .linear(let path): path.start
        case .circular(let path): path.start
        case .compound(let path): path.start
        }
    }
    public var end: Point {
        switch self {
        case .linear(let path): path.end
        case .circular(let path): path.end
        case .compound(let path): path.end
        }
    }
    public var startOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.startOrientation
        case .circular(let path): path.startOrientation
        case .compound(let path): path.startOrientation
        }
    }
    public var endOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.endOrientation
        case .circular(let path): path.endOrientation
        case .compound(let path): path.endOrientation
        }
    }
    public var length: Distance {
        switch self {
        case .linear(let path): path.length
        case .circular(let path): path.length
        case .compound(let path): path.length
        }
    }
    public var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): path.range
        case .circular(let path): path.range
        case .compound(let path): path.range
        }
    }
    public var reverse: SomeFinitePath {
        switch self {
        case .linear(let path): .linear(path.reverse)
        case .circular(let path): .circular(path.reverse)
        case .compound(let path): .compound(path.reverse)
        }
    }
    public var finitePathType: FinitePathType {
        switch self {
        case .linear: .linear
        case .circular: .circular
        case .compound: .compound
        }
    }

    public func offsetLeft(by d: Distance) -> SomeFinitePath? {
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
        case .compound(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                .compound(offsetPath)
            } else {
                nil
            }
        }
    }

    public func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): path.point(at: x)
        case .circular(let path): path.point(at: x)
        case .compound(let path): path.point(at: x)
        }
    }

    public func orientation(at x: Position) -> CircleAngle? {
        switch self {
        case .linear(let path): path.orientation(at: x)
        case .circular(let path): path.orientation(at: x)
        case .compound(let path): path.orientation(at: x)
        }
    }

    public func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.forwardAtomicPathType(at: x)
        case .circular(let path): path.forwardAtomicPathType(at: x)
        case .compound(let path): path.forwardAtomicPathType(at: x)
        }
    }

    public func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.backwardAtomicPathType(at: x)
        case .circular(let path): path.backwardAtomicPathType(at: x)
        case .compound(let path): path.backwardAtomicPathType(at: x)
        }
    }

    public func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): path.closestPointOnPath(from: p)
        case .circular(let path): path.closestPointOnPath(from: p)
        case .compound(let path): path.closestPointOnPath(from: p)
        }
    }

    public func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): path.pointsOnPath(atDistance: d, from: p)
        case .compound(let path): path.pointsOnPath(atDistance: d, from: p)
        }
    }

    public func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .compound(let path): path.firstPointOnPath(atDistance: d, after: x)
        }
    }

    public func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .compound(let path): path.lastPointOnPath(atDistance: d, before: x)
        }
    }

    public func segments(inRect rect: Rect) -> [ClosedRange<Position>] {
        switch self {
        case .linear(let path): path.segments(inRect: rect)
        case .circular(let path): path.segments(inRect: rect)
        case .compound(let path): path.segments(inRect: rect)
        }
    }

    public func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): path.split(at: x)
        case .circular(let path): path.split(at: x)
        case .compound(let path): path.split(at: x)
        }
    }

    public static func combine(_ a: SomeFinitePath, _ b: SomeFinitePath) -> SomeFinitePath? {
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
            } else if let path = CompoundPath(components: [.circular(a), .circular(b)]) {
                .compound(path)
            } else {
                nil
            }
        case (.linear(let a), .circular(let b)):
            if let path = CompoundPath(components: [.linear(a), .circular(b)]) {
                .compound(path)
            } else {
                nil
            }
        case (.circular(let a), .linear(let b)):
            if let path = CompoundPath(components: [.circular(a), .linear(b)]) {
                .compound(path)
            } else {
                nil
            }
        case (.linear(let a), .compound(let b)):
            if let path = CompoundPath.combine(.linear(a), b) {
                .compound(path)
            } else {
                nil
            }
        case (.circular(let a), .compound(let b)):
            if let path = CompoundPath.combine(.circular(a), b) {
                .compound(path)
            } else {
                nil
            }
        case (.compound(let a), .linear(let b)):
            if let path = CompoundPath.combine(a, .linear(b)) {
                .compound(path)
            } else {
                nil
            }
        case (.compound(let a), .circular(let b)):
            if let path = CompoundPath.combine(a, .circular(b)) {
                .compound(path)
            } else {
                nil
            }
        case (.compound(let a), .compound(let b)):
            if let path = CompoundPath.combine(a, b) {
                .compound(path)
            } else {
                nil
            }
        }
    }

    init(_ path: AtomicFinitePath) {
        switch path {
        case .linear(let path): self = .linear(path)
        case .circular(let path): self = .circular(path)
        }
    }

    public var atomic: AtomicFinitePath? {
        switch self {
        case .linear(let path): .linear(path)
        case .circular(let path): .circular(path)
        case .compound: nil
        }
    }

}

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

    init?(underlying: SomeFinitePath) {
        if canConnect(underlying.startPointAndOrientation, underlying.endPointAndOrientation) {
            return nil
        }
        self.underlying = underlying
    }

}
