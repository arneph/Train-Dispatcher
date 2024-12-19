//
//  FinitePath.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

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
            if let linear = self as? LinearPath {
                .linear(linear)
            } else if let circular = self as? CircularPath {
                .circular(circular)
            } else if let compound = self as? CompoundPath {
                .compound(compound)
            } else if let some = self as? SomeFinitePath {
                some
            } else {
                preconditionFailure("FinitePath has unexpected type.")
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

    public static func isDistance(
        between a: SomeFinitePath,
        and b: SomeFinitePath,
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
        case (.linear(let a), .compound(let b)):
            SomeFinitePath.isDistance(between: b, and: .linear(a), alwaysAbove: minDistance)
        case (.circular(let a), .compound(let b)):
            SomeFinitePath.isDistance(between: b, and: .circular(a), alwaysAbove: minDistance)
        case (.compound(let a), .linear(let b)):
            SomeFinitePath.isDistance(between: a, and: .linear(b), alwaysAbove: minDistance)
        case (.compound(let a), .circular(let b)):
            SomeFinitePath.isDistance(between: a, and: .circular(b), alwaysAbove: minDistance)
        case (.compound(let a), .compound(let b)):
            CompoundPath.isDistance(between: a, and: b, above: minDistance)
        }
    }

    private static func isDistance(
        between a: CompoundPath,
        and b: AtomicFinitePath,
        alwaysAbove minDistance: Distance
    ) -> Bool {
        for component in a.components {
            if !AtomicFinitePath.isDistance(between: component, and: b, above: minDistance) {
                return false
            }
        }
        return true
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
