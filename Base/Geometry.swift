//
//  Geometry.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation

public struct Point: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let x: Position
    public let y: Position

    public var asRect: Rect { Rect(origin: self, size: Size.zero) }

    public init(x: Position, y: Position) {
        self.x = x
        self.y = y
    }

    public var description: String { "(" + x.description + ", " + y.description + ")" }
    public var debugDescription: String {
        "(" + x.debugDescription + ", " + y.debugDescription + ")"
    }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public typealias Direction = Point

public struct NormDirection: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let x: Float64
    public let y: Float64
    public var angle: Angle { Angle(atan2(y, x)) }

    public init?(_ direction: Direction) {
        let length = length(direction)
        guard length != 0.0.m else { return nil }
        self.x = direction.x / length
        self.y = direction.y / length
    }

    public init(angle: Angle) {
        self.x = cos(angle)
        self.y = sin(angle)
    }

    public var description: String { String(format: "(%.3f, %.3f)", x, y) }
    public var debugDescription: String { String(format: "(%.3f, %.3f)", x, y) }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public struct Size: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let width: Distance
    public let height: Distance

    static public let zero = Size(width: Distance(0.0), height: Distance(0.0))

    public init(width: Distance, height: Distance) {
        self.width = width
        self.height = height
    }

    public var description: String { width.description + " x " + height.description }
    public var debugDescription: String { width.debugDescription + " x " + height.debugDescription }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public struct Rect: Equatable, Hashable, Codable, CustomStringConvertible,
    CustomDebugStringConvertible, CustomReflectable
{
    public let origin: Point
    public let size: Size

    public var x: Position { origin.x }
    public var y: Position { origin.y }
    public var width: Distance { size.width }
    public var height: Distance { size.height }

    public var minX: Position { origin.x }
    public var maxX: Position { origin.x + size.width }
    public var xRange: ClosedRange<Position> { minX...maxX }
    public var minY: Position { origin.y }
    public var maxY: Position { origin.y + size.height }
    public var yRange: ClosedRange<Position> { minY...maxY }

    public var minXY: Point { origin }
    public var maxXY: Point { Point(x: x + width, y: y + height) }

    public var corners: [Point] {
        [
            origin,
            Point(x: x + width, y: y),
            Point(x: x + width, y: y + height),
            Point(x: x, y: y + height),
        ]
    }
    public var lines: [Line] {
        let points = corners
        return [
            Line(through: points[0], and: points[1])!,
            Line(through: points[1], and: points[2])!,
            Line(through: points[2], and: points[3])!,
            Line(through: points[3], and: points[0])!,
        ]
    }

    public var bounds: Rect { self }

    public func contains(_ p: Point) -> Bool {
        xRange.contains(p.x) && yRange.contains(p.y)
    }

    public func contains(_ rect: Rect) -> Bool {
        contains(rect.minXY) && contains(rect.maxXY)
    }

    public func insetBy(dx: Distance, dy: Distance) -> Rect {
        Rect(x: x + dx, y: y + dy, width: width - 2.0 * dx, height: height - 2.0 * dy)
    }

    public static func union(_ a: Rect, _ b: Rect) -> Rect {
        let minX = min(a.minX, b.minX)
        let maxX = min(a.maxX, b.maxX)
        let minY = min(a.minY, b.minY)
        let maxY = min(a.maxY, b.maxY)
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public static func union(_ r: Rect, _ p: Point) -> Rect {
        let minX = min(r.minX, p.x)
        let maxX = min(r.maxX, p.x)
        let minY = min(r.minY, p.y)
        let maxY = min(r.maxY, p.y)
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    public static func square(around p: Point, length: Distance) -> Rect {
        Rect(x: p.x - length / 2.0, y: p.y - length / 2.0, width: length, height: length)
    }

    public static func intersect(_ a: Rect, _ b: Rect) -> Bool {
        a.xRange.overlaps(b.xRange) && a.yRange.overlaps(b.yRange)
    }

    public static func intersection(_ a: Rect, _ b: Rect) -> Rect? {
        guard intersect(a, b) else { return nil }
        return Rect(
            x: max(a.x, b.x),
            y: max(a.y, b.y),
            width: min(a.maxX, b.maxX) - max(a.x, b.x),
            height: min(a.maxY, b.maxY) - max(a.y, b.y))
    }

    public init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }

    public init(x: Position, y: Position, width: Distance, height: Distance) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }

    public init(p1: Point, p2: Point) {
        self.origin = Point(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
        self.size = Size(width: abs(p2.x - p1.x), height: abs(p2.y - p1.y))
    }

    public var description: String { minXY.description + "..." + maxXY.description }
    public var debugDescription: String { minXY.debugDescription + "..." + maxXY.debugDescription }
    public var customMirror: Mirror { Mirror(reflecting: self.description) }
}

public func + (lhs: Point, rhs: Direction) -> Point {
    Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

public func - (lhs: Point, rhs: Direction) -> Point {
    Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

public func += (lhs: inout Point, rhs: Direction) {
    lhs = lhs + rhs
}

public func -= (lhs: inout Point, rhs: Direction) {
    lhs = lhs - rhs
}

public func * (lhs: Float64, rhs: Direction) -> Direction {
    Direction(x: lhs * rhs.x, y: lhs * rhs.y)
}

public func * (lhs: Direction, rhs: Float64) -> Direction {
    Direction(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func * (lhs: Distance, rhs: NormDirection) -> Direction {
    Direction(x: lhs * rhs.x, y: lhs * rhs.y)
}

public func * (lhs: NormDirection, rhs: Distance) -> Direction {
    Direction(x: lhs.x * rhs, y: lhs.y * rhs)
}

public func / (lhs: Direction, rhs: Float64) -> Direction {
    Direction(x: lhs.x / rhs, y: lhs.y / rhs)
}

public func angle(from a: Point, to b: Point) -> Angle {
    Angle(atan2((b.y - a.y).withoutUnit, (b.x - a.x).withoutUnit))
}

public func length(_ direction: Direction) -> Distance {
    Distance(hypot(direction.x.withoutUnit, direction.y.withoutUnit))
}

public func length²(_ direction: Direction) -> Distance² {
    pow²(direction.x) + pow²(direction.y)
}

public func scalar(_ a: Direction, _ b: Direction) -> Distance² {
    a.x * b.x + a.y * b.y
}

public func scalar(_ a: Direction, _ b: NormDirection) -> Distance {
    a.x * b.x + a.y * b.y
}

public func cross(_ a: Direction, _ b: Direction) -> Distance² {
    a.x * b.y - a.y * b.x
}

public func direction(from a: Point, to b: Point) -> Direction {
    Direction(x: b.x - a.x, y: b.y - a.y)
}

public func distance(_ a: Point, _ b: Point) -> Distance {
    length(direction(from: a, to: b))
}

public func distance²(_ a: Point, _ b: Point) -> Distance² {
    length²(direction(from: a, to: b))
}

infix operator ** : MultiplicationPrecedence

public func ** (lhs: Distance, rhs: Angle) -> Direction {
    Direction(x: lhs * cos(rhs), y: lhs * sin(rhs))
}

public func ** (lhs: Angle, rhs: Distance) -> Direction {
    Direction(x: rhs * cos(lhs), y: rhs * sin(lhs))
}

public struct Line {
    public let base: Point
    public let direction: NormDirection
    public var orientation: Angle { direction.angle }

    public init?(base: Point, direction: Direction) {
        guard let normDireciton = NormDirection(direction) else { return nil }
        self.base = base
        self.direction = normDireciton
    }

    public init?(through a: Point, and b: Point) {
        guard
            let normDirection = NormDirection(Base.direction(from: a, to: b))
        else {
            return nil
        }
        self.base = a
        self.direction = normDirection
    }

    public init(base: Point, orientation: Angle) {
        self.base = base
        self.direction = NormDirection(angle: orientation)
    }

    public func point(at s: Distance) -> Point {
        base + direction * s
    }

    public func arg(for point: Point) -> Distance? {
        let d = point - base
        let s1 = d.x / direction.x
        let s2 = d.y / direction.y
        return if orientation.isHorizontal {
            d.y == 0.0.m ? s1 : nil
        } else if orientation.isVertical {
            d.x == 0.0.m ? s2 : nil
        } else {
            s1 == s2 ? s1 : nil
        }
    }

    public func closestPoint(to target: Point) -> Point {
        let d = Base.direction(from: base, to: target)
        return base + direction * scalar(d, direction)
    }

    public func argsForPoints(atDistance radius: Distance, from center: Point) -> [Distance] {
        let d = base - center
        let a = direction.x * direction.x + direction.y * direction.y
        let b = 2.0 * (d.x * direction.x + d.y * direction.y)
        let c = d.x * d.x + d.y * d.y - radius * radius
        let discriminant = b * b - 4.0 * a * c
        if discriminant < 0.0.m² { return [] }
        if discriminant == 0.0.m² { return [-b / (2.0 * a)] }
        let s1 = (-b + sqrt(discriminant)) / (2.0 * a)
        let s2 = (-b - sqrt(discriminant)) / (2.0 * a)
        return [s1, s2].sorted()
    }

    public static func intersection(_ a: Line, _ b: Line) -> Point? {
        let p1 = a.base
        let p2 = a.base + a.direction * 1.0.m
        let p3 = b.base
        let p4 = b.base + b.direction * 1.0.m
        let d12 = p1 - p2
        let d34 = p3 - p4
        let denominator = cross(d12, d34)
        guard denominator != 0.0.m² else { return nil }
        let c1 = cross(p1, p2)
        let c2 = cross(p3, p4)
        let x = (c1 * d34.x - d12.x * c2) / denominator
        let y = (c1 * d34.y - d12.y * c2) / denominator
        return Point(x: x, y: y)
    }

    public static func argsForIntersection(_ a: Line, _ b: Line) -> (Distance, Distance)? {
        let p1 = a.base
        let p2 = a.base + a.direction * 1.0.m
        let p3 = b.base
        let p4 = b.base + b.direction * 1.0.m
        let denominator = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x)
        guard denominator != 0.0.m² else { return nil }
        let r = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denominator
        let s = -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) / denominator
        return (Distance(r), Distance(s))
    }

}
