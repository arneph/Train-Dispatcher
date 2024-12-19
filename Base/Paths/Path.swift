//
//  Path.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/19/24.
//

import Foundation

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

    static func isDistance(between a: Self, and b: Self, above minDistance: Distance) -> Bool
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

public func canConnect(_ a: PointAndOrientation, _ b: PointAndOrientation) -> Bool {
    distance(a.point, b.point) < minDistance && absDiff(a.orientation, b.orientation) <= minAngle
}
