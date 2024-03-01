//
//  Geometry.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation

struct Point: Equatable,
              Hashable,
              Codable,
              CustomStringConvertible,
              CustomDebugStringConvertible,
              CustomReflectable {
    let x: Position
    let y: Position
        
    var asRect: Rect { Rect(orign: self, size: Size.zero) }
    
    init(x: Position, y: Position) {
        self.x = x
        self.y = y
    }
    
    var description: String { "(" + x.description + ", " + y.description + ")" }
    var debugDescription: String { "(" + x.debugDescription + ", " + y.debugDescription + ")" }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}

typealias Direction = Point

struct NormDirection: Equatable, 
                      Hashable,
                      Codable,
                      CustomStringConvertible,
                      CustomDebugStringConvertible,
                      CustomReflectable {
    let x: Float64
    let y: Float64
    var angle: Angle { Angle(atan2(y, x)) }
    
    init?(_ direction: Direction) {
        let length = length(direction)
        guard length != 0.0.m else { return nil }
        self.x = direction.x / length
        self.y = direction.y / length
    }
    
    init(angle: Angle) {
        self.x = cos(angle)
        self.y = sin(angle)
    }
    
    var description: String { String(format: "(%.3f, %.3f)", x, y) }
    var debugDescription: String { String(format: "(%.3f, %.3f)", x, y) }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}

struct Size: Equatable,
             Hashable,
             Codable,
             CustomStringConvertible,
             CustomDebugStringConvertible,
             CustomReflectable{
    let width: Distance
    let height: Distance
        
    static let zero = Size(width: Distance(0.0),
                           height: Distance(0.0))
    
    init(width: Distance, height: Distance) {
        self.width = width
        self.height = height
    }
    
    var description: String { width.description + " x " + height.description }
    var debugDescription: String { width.debugDescription + " x " + height.debugDescription }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}

struct Rect : Equatable,
              Hashable,
              Codable,
              CustomStringConvertible,
              CustomDebugStringConvertible,
              CustomReflectable {
    let origin: Point
    let size: Size
    
    var x: Position { origin.x }
    var y: Position { origin.y }
    var width: Distance { size.width }
    var height: Distance { size.height }
    
    var minX: Position { origin.x }
    var maxX: Position { origin.x + size.width }
    var xRange: ClosedRange<Position> { minX...maxX }
    var minY: Position { origin.y }
    var maxY: Position { origin.y + size.height }
    var yRange: ClosedRange<Position> { minY...maxY }
    
    var minXY: Point { origin }
    var maxXY: Point { Point(x: x + width, y: y + height) }
        
    var bounds: Rect { self }
    
    func insetBy(dx: Distance, dy: Distance) -> Rect {
        Rect(x: x + dx,
             y: y + dy,
             width: width - 2.0 * dx,
             height: height - 2.0 * dy)
    }
    
    static func union(_ a: Rect, _ b: Rect) -> Rect {
        let minX = min(a.minX, b.minX)
        let maxX = min(a.maxX, b.maxX)
        let minY = min(a.minY, b.minY)
        let maxY = min(a.maxY, b.maxY)
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    static func union(_ r: Rect, _ p: Point) -> Rect {
        let minX = min(r.minX, p.x)
        let maxX = min(r.maxX, p.x)
        let minY = min(r.minY, p.y)
        let maxY = min(r.maxY, p.y)
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    static func square(around p: Point, length: Distance) -> Rect {
        Rect(x: p.x - length / 2.0,
             y: p.y - length / 2.0,
             width: length,
             height: length)
    }
    
    static func intersect(_ a: Rect, _ b: Rect) -> Bool {
        a.xRange.overlaps(b.xRange) && a.yRange.overlaps(b.yRange)
    }
    
    init(orign: Point, size: Size) {
        self.origin = orign
        self.size = size
    }
    
    init(x: Position, y: Position, width: Distance, height: Distance) {
        self.origin = Point(x: x, y: y)
        self.size = Size(width: width, height: height)
    }
    
    init(p1: Point, p2: Point) {
        self.origin = Point(x: min(p1.x, p2.x), y: min(p1.y, p2.y))
        self.size = Size(width: abs(p2.x - p1.x), height: abs(p2.y - p1.y))
    }
    
    var description: String { minXY.description + "..." + maxXY.description }
    var debugDescription: String { minXY.debugDescription + "..." + maxXY.debugDescription }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}

func + (lhs: Point, rhs: Direction) -> Point {
    Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

func - (lhs: Point, rhs: Direction) -> Point {
    Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

func += (lhs: inout Point, rhs: Direction) {
    lhs = lhs + rhs
}

func -= (lhs: inout Point, rhs: Direction) {
    lhs = lhs - rhs
}

func * (lhs: Float64, rhs: Direction) -> Direction {
    Direction(x: lhs * rhs.x,
              y: lhs * rhs.y)
}

func * (lhs: Direction, rhs: Float64) -> Direction {
    Direction(x: lhs.x * rhs,
              y: lhs.y * rhs)
}

func * (lhs: Distance, rhs: NormDirection) -> Direction {
    Direction(x: lhs * rhs.x,
              y: lhs * rhs.y)
}

func * (lhs: NormDirection, rhs: Distance) -> Direction {
    Direction(x: lhs.x * rhs,
              y: lhs.y * rhs)
}

func / (lhs: Direction, rhs: Float64) -> Direction {
    Direction(x: lhs.x / rhs,
              y: lhs.y / rhs)
}

func angle(from a: Point, to b: Point) -> Angle {
    Angle(atan2((b.y - a.y).withoutUnit, (b.x - a.x).withoutUnit))
}

func length(_ direction: Direction) -> Distance {
    Distance(hypot(direction.x.withoutUnit, direction.y.withoutUnit))
}

func length²(_ direction: Direction) -> Distance² {
    pow²(direction.x) + pow²(direction.y)
}

func scalar(_ a: Direction, _ b: Direction) -> Distance² {
    a.x * b.x + a.y * b.y
}

func scalar(_ a: Direction, _ b: NormDirection) -> Distance {
    a.x * b.x + a.y * b.y
}

func cross(_ a: Direction, _ b: Direction) -> Distance² {
    a.x * b.y - a.y * b.x
}

func direction(from a: Point, to b: Point) -> Direction {
    Direction(x: b.x - a.x, y: b.y - a.y)
}

func distance(_ a: Point, _ b: Point) -> Distance {
    length(direction(from: a, to: b))
}

func distance²(_ a: Point, _ b: Point) -> Distance² {
    length²(direction(from: a, to: b))
}

infix operator **: MultiplicationPrecedence

func ** (lhs: Distance, rhs: Angle) -> Direction {
    Direction(x: lhs * cos(rhs), y: lhs * sin(rhs))
}

func ** (lhs: Angle, rhs: Distance) -> Direction {
    Direction(x: rhs * cos(lhs), y: rhs * sin(lhs))
}

struct Line {
    let base: Point
    let direction: NormDirection
    var orientation: Angle { direction.angle }
    
    init?(base: Point, direction: Direction) {
        guard let normDireciton = NormDirection(direction) else { return nil }
        self.base = base
        self.direction = normDireciton
    }
    
    init?(through a: Point, and b: Point) {
        guard let normDirection = NormDirection(Train_Dispatcher.direction(from: a, to: b)) else {
            return nil
        }
        self.base = a
        self.direction = normDirection
    }
    
    init(base: Point, orientation: Angle) {
        self.base = base
        self.direction = NormDirection(angle: orientation)
    }
    
    func point(at s: Distance) -> Point {
        base + direction * s
    }
    
    func closestPoint(to target: Point) -> Point {
        let d = Train_Dispatcher.direction(from: base, to: target)
        return base + direction * scalar(d, direction)
    }
    
    static func intersection(_ a: Line, _ b: Line) -> Point? {
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
}
