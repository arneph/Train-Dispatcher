//
//  Geometry.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation

struct Point : Equatable, Hashable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
    let x: Position
    let y: Position
    
    var xValue: Float64 { x.withoutUnit }
    var yValue: Float64 { y.withoutUnit }
    
    var asRect: Rect { Rect(orign: self, size: Size.zero) }
    
    init(x: Position, y: Position) {
        self.x = x
        self.y = y
    }
    
    var description: String { "(" + x.description + ", " + y.description + ")" }
    var debugDescription: String { "(" + x.debugDescription + ", " + y.debugDescription + ")" }
    
}

typealias Direction = Point

struct Size : Equatable, Hashable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
    let width: Distance
    let height: Distance
    
    var widthValue: Float64 { width.withoutUnit }
    var heightValue: Float64 { height.withoutUnit }
    
    static let zero = Size(width: Distance(0.0),
                           height: Distance(0.0))
    
    init(width: Distance, height: Distance) {
        self.width = width
        self.height = height
    }
    
    var description: String { width.description + " x " + height.description }
    var debugDescription: String { width.debugDescription + " x " + height.debugDescription }
    
}

struct Rect : Equatable, Hashable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
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
    
    var xValue: Float64 { origin.xValue }
    var yValue: Float64 { origin.yValue }
    var widthValue: Float64 { size.widthValue }
    var heightValue: Float64 { size.heightValue }
    
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

infix operator **: MultiplicationPrecedence

func ** (lhs: Distance, rhs: Angle) -> Direction {
    Direction(x: lhs * cos(rhs), y: lhs * sin(rhs))
}

func ** (lhs: Angle, rhs: Distance) -> Direction {
    Direction(x: rhs * cos(lhs), y: rhs * sin(lhs))
}

func closestPointOnLine(through p: Point, 
                        withOrientation orientation: Angle,
                        to target: Point) -> Point {
    closestPointOnLine(through: p, andThrough: p + 1.0.m ** orientation, to: target)
}

func closestPointOnLine(through p: Point, 
                        withDirection direction: Direction,
                        to target: Point) -> Point {
    closestPointOnLine(through: p, andThrough: p + direction, to: target)
}

func closestPointOnLine(through a: Point, andThrough b: Point, to target: Point) -> Point {
    let l = direction(from: a, to: b)
    let d = direction(from: a, to: target)
    return a + d * (scalar(d, l) / scalar(l, l))
}
