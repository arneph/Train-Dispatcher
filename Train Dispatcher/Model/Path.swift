//
//  Path.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/19/24.
//

import Foundation

fileprivate let minDistance = 0.001.m
fileprivate let minAngle = 0.001.deg

let epsilon = Distance(1e-6)

func isApproximatelyEqual(x: Position, y: Position) -> Bool { abs(x - y) < epsilon }
func isApproximatelyLessThan(x: Position, y: Position) -> Bool { x - y < -epsilon }
func isApproximatelyGreaterThan(x: Position, y: Position) -> Bool { x - y > +epsilon }

func isApproximatelyInRange(x: Position,
                            range: ClosedRange<Position>) -> Bool {
    range.lowerBound <= x + epsilon && x - epsilon <= range.upperBound
}

struct PointAndOrientation: Equatable, Hashable, Codable {
    let point: Point
    let orientation: CircleAngle
}

enum PathExtremity: Equatable, Hashable, Codable {
    case start, end
}

enum AtomicPathType: Equatable, Hashable, Codable {
    case linear, circular
}

enum FinitePathType: Equatable, Hashable, Codable {
    case linear, circular, compound
    
    var atomicPathType: AtomicPathType? {
        switch self {
        case .linear: .linear
        case .circular: .circular
        case .compound: nil
        }
    }
    
    init(_ atomicPathType: AtomicPathType) {
        switch atomicPathType {
        case .linear: self = .linear
        case .circular: self = .circular
        }
    }
}

struct ClosestPathPointInfo: Equatable, Hashable, Codable {
    enum AtomicPathInfo: Equatable, Hashable, Codable {
        case singleAtomicPath(AtomicPathType)
        case twoAtomicPathsConnection(AtomicPathType, AtomicPathType)
    }
    enum SpecialCase: Equatable, Hashable, Codable {
        case no, start, end
    }
    
    let distance: Distance
    let x: Position
    let atomicPathInfo: AtomicPathInfo
    let specialCase: SpecialCase
}

protocol Path: Equatable, Hashable, Codable {
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
    func offsetRight(by d: Distance) -> Self? { offsetLeft(by: -d) }
    
    func normalize(_ x: Position) -> Position { x }
    
    func pointAndOrientation(at x: Position) -> PointAndOrientation? {
        guard let point = point(at: x), let orientation = orientation(at: x) else {
            return nil
        }
        return PointAndOrientation(point: point, orientation: orientation)
    }
}

protocol FinitePath: Path {
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
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)?
    static func combine(_ a: Self, _ b: Self) -> Self?
    static func combine(_ paths: [Self]) -> Self?
}

extension FinitePath {
    var startPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: start, orientation: startOrientation)
    }
    var endPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: end, orientation: endOrientation)
    }
    
    static func combine(_ paths: [Self]) -> Self? {
        guard !paths.isEmpty else { return nil }
        var combined = paths.first!
        for path in paths.dropFirst() {
            guard let result = Self.combine(combined, path) else { return nil }
            combined = result
        }
        return combined
    }
}

func canConnect(_ a: PointAndOrientation, _ b: PointAndOrientation) -> Bool {
    distance(a.point, b.point) < minDistance && absDiff(a.orientation, b.orientation) <= minAngle
}

struct LinearPath: FinitePath {
    let start: Point
    let end: Point
    var orientation: CircleAngle { CircleAngle(angle(from: start, to: end)) }
    var startOrientation: CircleAngle { orientation }
    var endOrientation: CircleAngle { orientation }
    var direction: Direction { Train_Dispatcher.direction(from: start, to: end) }
    var normDirection: Direction { Train_Dispatcher.normalize(direction) }
    var length: Distance { distance(start, end) }
    var range: ClosedRange<Position> { Position(0.0)...length }
    var reverse: LinearPath { LinearPath(start: end, end: start)! }
    var finitePathType: FinitePathType { .linear }
    
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
    
    func offsetLeft(by d: Distance) -> LinearPath? {
        LinearPath(start: start + d ** left, end: end + d ** left)!
    }
        
    func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        let progress = x / length
        return start + (end - start) * progress
    }
    
    func orientation(at x: Position) -> CircleAngle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return orientation
    }
    
    func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m <= x && x < length { .linear } else { nil }
    }
    func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m < x && x <= length { .linear } else { nil }
    }
    
    func closestPointOnPath(from target: Point) -> ClosestPathPointInfo {
        let deltaDirection = Train_Dispatcher.direction(from: start, to: target)
        let projectedDist = scalar(deltaDirection, direction) / length
        if range.contains(projectedDist) {
            let projectedPoint = start + (projectedDist * normDirection)
            let distToProjectedPoint = Train_Dispatcher.distance(target, projectedPoint)
            return ClosestPathPointInfo(distance: distToProjectedPoint,
                                        x: projectedDist,
                                        atomicPathInfo: .singleAtomicPath(.linear),
                                        specialCase: .no)
        }
        let distToStart = Train_Dispatcher.distance(target, start)
        let distToEnd = Train_Dispatcher.distance(target, end)
        if distToStart < distToEnd {
            return ClosestPathPointInfo(distance: distToStart,
                                        x: 0.0.m,
                                        atomicPathInfo: .singleAtomicPath(.linear),
                                        specialCase: .start)
        } else {
            return ClosestPathPointInfo(distance: distToEnd, 
                                        x: length,
                                        atomicPathInfo: .singleAtomicPath(.linear),
                                        specialCase: .end)
        }
    }
    
    func pointsOnPath(atDistance r: Distance, from: Point) -> [Position] {
        let a = distance²(start, end)
        let b = 2.0 * scalar(Train_Dispatcher.direction(from: start, to: end),
                             Train_Dispatcher.direction(from: from, to: start))
        let c = distance²(start, from) - pow²(r)
        let d = pow²(b) - 4.0 * a * c
        if d < Distance⁴(0.0) {
            return []
        } else if d == Distance⁴(0.0) {
            let x = 0.5 * -b / length
            return [x].filter{ range.contains($0) }
        } else {
            let x1 = 0.5 * (-b - sqrt(d)) / length
            let x2 = 0.5 * (-b + sqrt(d)) / length
            return [x1, x2].filter{ range.contains($0) }
        }
    }
    
    func firstPointOnPath(atDistance d: Distance,
                          after min: Position) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: min)!).filter{ min <= $0 }.first
    }
    
    func lastPointOnPath(atDistance d: Distance,
                         before max: Position) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: max)!).filter{ $0 <= max }.last
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if x <= 0.0.m || x >= length {
            return nil
        }
        let p = point(at: x)!
        return (.linear(LinearPath(start: start, end: p)!),
                .linear(LinearPath(start: p, end: end)!))
    }
    
    static func combine(_ a: LinearPath, _ b: LinearPath) -> LinearPath? {
        guard canConnect(a.endPointAndOrientation, b.startPointAndOrientation) else {
            return nil
        }
        return LinearPath(start: a.start, end: b.end)!
    }
    
    init?(start: Point, end: Point) {
        if start == end {
            return nil
        }
        self.start = start
        self.end = end
    }
    
}

struct CircularPath: FinitePath {
    let center: Point
    let radius: Distance
    let circleRange: CircleRange
    
    private func toOrientation(_ a: CircleAngle) -> CircleAngle {
        switch circleRange.direction {
        case .positive: CircleAngle(a + 90.0.deg)
        case .negative: CircleAngle(a - 90.0.deg)
        }
    }
    
    var start: Point { center + radius ** circleRange.startAngle }
    var end: Point { center + radius ** circleRange.endAngle }
    var startOrientation: CircleAngle { toOrientation(circleRange.start) }
    var endOrientation: CircleAngle { toOrientation(circleRange.end) }
    var length: Distance { radius * circleRange.absDelta.withoutUnit }
    var range: ClosedRange<Position> { Position(0.0)...length }
    var reverse: CircularPath {
        CircularPath(center: center, radius: radius, circleRange: circleRange.flipped)!
    }
    var finitePathType: FinitePathType { .circular }
    
    func offsetLeft(by d: Distance) -> CircularPath? {
        let offsetRadius: Distance
        switch circleRange.direction {
        case .positive: offsetRadius = radius - d
        case .negative: offsetRadius = radius + d
        }
        return CircularPath(center: center, radius: offsetRadius, circleRange: circleRange)
    }
    
    private func toCircleAngle(_ x: Position) -> CircleAngle {
        CircleAngle(circleRange.start + circleRange.delta * (x / length))
    }
    
    private func toOrientation(_ x: Position) -> CircleAngle { toOrientation(toCircleAngle(x)) }
    
    private func toPosition(_ a: CircleAngle) -> Position {
        circleRange.fraction(for: a) * length
    }
    
    func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return center + radius ** toCircleAngle(x).asAngle
    }
    
    func orientation(at x: Position) -> CircleAngle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return toOrientation(x)
    }
    
    func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m <= x && x < length { .circular } else { nil }
    }
    func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        if 0.0.m < x && x <= length { .circular } else { nil }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        let circleAngle = CircleAngle(angle(from: center, to: p))
        if circleRange.contains(circleAngle) {
            return ClosestPathPointInfo(distance: abs(distance(p, center) - radius),
                                        x: toPosition(circleAngle),
                                        atomicPathInfo: .singleAtomicPath(.circular),
                                        specialCase: .no)
        }
        let distToStart = distance(p, start)
        let distToEnd = distance(p, end)
        return distToStart < distToEnd
            ? ClosestPathPointInfo(distance: distToStart,
                                   x: 0.0.m,
                                   atomicPathInfo: .singleAtomicPath(.circular),
                                   specialCase: .start)
            : ClosestPathPointInfo(distance: distToEnd, 
                                   x: length,
                                   atomicPathInfo: .singleAtomicPath(.circular),
                                   specialCase: .end)
    }
    
    func pointsOnPath(atDistance distToPoints: Distance, from p: Point) -> [Position] {
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
        return [angle1, angle2].filter{ circleRange.contains($0) }.map{ toPosition($0) }.sorted()
    }
    
    func firstPointOnPath(atDistance d: Distance,
                          after min: Position) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: min)!).filter{ min <= $0 }.first
    }
    
    func lastPointOnPath(atDistance d: Distance,
                         before max: Position) -> Position? {
        pointsOnPath(atDistance: d, from: point(at: max)!).filter{ $0 <= max }.last
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if !range.contains(x) {
            return nil
        }
        if let (splitCircleRange1, splitCircleRange2) = circleRange.split(at: toCircleAngle(x)) {
            return (.circular(CircularPath(center: center,
                                           radius: radius,
                                           circleRange: splitCircleRange1)!),
                    .circular(CircularPath(center: center,
                                           radius: radius,
                                           circleRange: splitCircleRange2)!))
        } else {
            return nil
        }
    }
    
    static func combine(_ a: CircularPath, _ b: CircularPath) -> CircularPath? {
        guard let circleRange = CircleRange.combine(a.circleRange, b.circleRange),
              a.center == b.center,
              a.radius == b.radius else {
            return nil
        }
        return CircularPath(center: a.center, radius: a.radius, circleRange: circleRange)
    }
    
    init?(center: Point,
          radius: Distance,
          circleRange: CircleRange) {
        if radius * circleRange.absDelta.withoutUnit < 0.001.m {
            return nil
        }
        self.center = center
        self.radius = radius
        self.circleRange = circleRange
    }
    
    init?(center: Point, radius: Distance, startAngle: CircleAngle, deltaAngle: AngleDiff) {
        self.init(center: center,
                  radius: radius,
                  circleRange: CircleRange(start: startAngle, delta: deltaAngle))
    }
    
    init?(center: Point,
          radius: Distance,
          startAngle: CircleAngle,
          endAngle: CircleAngle,
          direction: CircleRange.Direction) {
        self.init(center: center,
                  radius: radius,
                  circleRange: CircleRange(start: startAngle, end: endAngle, direction: direction))
    }
    
}

enum AtomicFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)
    
    var start: Point {
        switch self {
        case .linear(let path): path.start
        case .circular(let path): path.start
        }
    }
    var end: Point {
        switch self {
        case .linear(let path): path.end
        case .circular(let path): path.end
        }
    }
    var startOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.startOrientation
        case .circular(let path): path.startOrientation
        }
    }
    var endOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.endOrientation
        case .circular(let path): path.endOrientation
        }
    }
    var length: Distance {
        switch self {
        case .linear(let path): path.length
        case .circular(let path): path.length
        }
    }
    var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): path.range
        case .circular(let path): path.range
        }
    }
    var reverse: AtomicFinitePath {
        switch self {
        case .linear(let path): .linear(path.reverse)
        case .circular(let path): .circular(path.reverse)
        }
    }
    var finitePathType: FinitePathType {
        switch self {
        case .linear: .linear
        case .circular: .circular
        }
    }
    
    func offsetLeft(by d: Distance) -> AtomicFinitePath? {
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
        
    func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): path.point(at: x)
        case .circular(let path): path.point(at: x)
        }
    }
    
    func orientation(at x: Position) -> CircleAngle? {
        switch self {
        case .linear(let path): path.orientation(at: x)
        case .circular(let path): path.orientation(at: x)
        }
    }
    
    func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.forwardAtomicPathType(at: x)
        case .circular(let path): path.forwardAtomicPathType(at: x)
        }
    }
    func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.backwardAtomicPathType(at: x)
        case .circular(let path): path.backwardAtomicPathType(at: x)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): path.closestPointOnPath(from: p)
        case .circular(let path): path.closestPointOnPath(from: p)
        }
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): path.pointsOnPath(atDistance: d, from: p)
        }
    }
    
    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): path.firstPointOnPath(atDistance: d, after: x)
        }
    }
    
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): path.lastPointOnPath(atDistance: d, before: x)
        }
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): path.split(at: x)
        case .circular(let path): path.split(at:x)
        }
    }
    
    static func combine(_ a: AtomicFinitePath, _ b: AtomicFinitePath) -> AtomicFinitePath? {
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

struct CompoundPath: FinitePath {
    private struct Context {
        let globalStart: Position
        let globalEnd: Position
        var globalRange: ClosedRange<Position> { globalStart...globalEnd }
        
        func toLocal(_ xGlobal: Position) -> Position { xGlobal - globalStart }
        func toGlobal(_ xLocal: Position) -> Position { globalStart + xLocal }
    }
    let components: [AtomicFinitePath]
    private let contexts: [Context]

    var componentSplitPositions: [Position] { contexts.dropFirst().map{ $0.globalStart } }
    
    var start: Point { components.first!.start }
    var end: Point { components.last!.end }
    var startOrientation: CircleAngle { components.first!.startOrientation }
    var endOrientation: CircleAngle { components.last!.endOrientation }
    var length: Distance { components.map{$0.length}.reduce(Distance(0.0), +) }
    var range: ClosedRange<Position> { Position(0.0)...length }
    var reverse: CompoundPath {
        CompoundPath(checkedComponents: components.map{$0.reverse}.reversed())
    }
    var finitePathType: FinitePathType { .compound }
    
    func offsetLeft(by d: Distance) -> CompoundPath? {
        let offsetAtomicFinitePaths = components.compactMap({ $0.offsetLeft(by: d) })
        guard offsetAtomicFinitePaths.count == components.count else {
            return nil
        }
        return CompoundPath(checkedComponents: offsetAtomicFinitePaths)
    }
    
    func component(at xGlobal: Position) -> (component: AtomicFinitePath, xLocal: Position)? {
        for (component, context) in zip(components, contexts) {
            if isApproximatelyInRange(x: xGlobal, range: context.globalRange) {
                return (component, context.toLocal(xGlobal))
            }
        }
        return nil
    }
    
    private func indexAndAtomicFinitePath(at xGlobal: Position) -> (index: Int,
                                                                    component: AtomicFinitePath,
                                                                    xLocal: Position)? {
        for (index, componentAndContext) in zip(components, contexts).enumerated() {
            let (component, context) = componentAndContext
            if isApproximatelyInRange(x: xGlobal, range: context.globalRange) {
                return (index, component, context.toLocal(xGlobal))
            }
        }
        return nil
    }
    
    func point(at xGlobal: Position) -> Point? {
        guard let (component, xLocal) = component(at: xGlobal) else {
            return nil
        }
        return component.point(at: xLocal)
    }
    
    func orientation(at xGlobal: Position) -> CircleAngle? {
        guard let (component, xLocal) = component(at: xGlobal) else {
            return nil
        }
        return component.orientation(at: xLocal)
    }
    
    func forwardAtomicPathType(at xGlobal: Position) -> AtomicPathType? {
        guard let (index, component, xLocal) = indexAndAtomicFinitePath(at: xGlobal) else {
            return nil
        }
        if index < components.count - 1 && xLocal == component.length {
            return components[index + 1].forwardAtomicPathType(at: 0.0.m)
        } else {
            return component.forwardAtomicPathType(at: xLocal)
        }
    }
    
    func backwardAtomicPathType(at xGlobal: Position) -> AtomicPathType? {
        guard let (index, component, xLocal) = indexAndAtomicFinitePath(at: xGlobal) else {
            return nil
        }
        if index > 0 && xLocal == 0.0.m {
            return components[index - 1].backwardAtomicPathType(at: components[index - 1].length)
        } else {
            return component.backwardAtomicPathType(at: xLocal)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        zip(components, contexts).enumerated().map{
            (index: Int,
             componentAndContext: (AtomicFinitePath, Context)) -> ClosestPathPointInfo in
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
            return ClosestPathPointInfo(distance: localPoint.distance,
                                        x: context.toGlobal(localPoint.x),
                                        atomicPathInfo: atomicPathInfo,
                                        specialCase: specialCase)
        }.min(by: { $0.distance < $1.distance })!
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        zip(components, contexts)
            .flatMap{ (component: AtomicFinitePath, context: Context) -> [Position] in
                component.pointsOnPath(atDistance: d, from: p)
                         .map{ context.toGlobal($0) }}
            .reduce([]) { xs, x in isApproximatelyEqual(x: xs.last ?? Position(-1.0), y: x)
                                   ? xs : (xs + [x]) }
    }
    
    func firstPointOnPath(atDistance d: Distance, after minGlobal: Position) -> Position? {
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
    
    func lastPointOnPath(atDistance d: Distance, before maxGlobal: Position) -> Position? {
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
                    return context.toLocal(xLocal)
                }
            }
        }
        return nil
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
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
        return (CompoundPath.combine(splitPaths: componentsA),
                CompoundPath.combine(splitPaths: componentsB))
    }
    
    private static func combine(splitPaths paths: [AtomicFinitePath]) -> SomeFinitePath {
        if paths.count == 1 {
            SomeFinitePath(paths.first!)
        } else {
            .compound(CompoundPath(checkedComponents: paths))
        }
    }
    
    static func combine(_ a: CompoundPath, _ b: CompoundPath) -> CompoundPath? {
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
    
    static func combine(_ a: AtomicFinitePath, _ b: CompoundPath) -> CompoundPath? {
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
    
    static func combine(_ a: CompoundPath, _ b: AtomicFinitePath) -> CompoundPath? {
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
    
    static func == (lhs: CompoundPath, rhs: CompoundPath) -> Bool {
        lhs.components == rhs.components
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(components)
    }
    
    init?(components: [AtomicFinitePath]) {
        if components.count < 2 {
            return nil
        }
        for index in 0...components.count - 2 {
            guard components[index].end == components[index + 1].start,
                  components[index].endOrientation == components[index + 1].startOrientation else {
                return nil
            }
        }
        self.init(checkedComponents: components)
    }
    
    private init(checkedComponents components: [AtomicFinitePath]) {
        self.components = components
        var x = 0.0.m
        self.contexts = components.map{ (component) in
            let globalStart = x
            let globalEnd = x + component.length
            x = globalEnd
            return Context(globalStart: globalStart, globalEnd: globalEnd)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case components
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let components = try values.decode([AtomicFinitePath].self, forKey: .components)
        self.init(checkedComponents: components)
    }
    
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(components, forKey: .components)
    }
    
}

enum SomeFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)
    case compound(CompoundPath)
    
    var start: Point {
        switch self {
        case .linear(let path): path.start
        case .circular(let path): path.start
        case .compound(let path): path.start
        }
    }
    var end: Point {
        switch self {
        case .linear(let path): path.end
        case .circular(let path): path.end
        case .compound(let path): path.end
        }
    }
    var startOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.startOrientation
        case .circular(let path): path.startOrientation
        case .compound(let path): path.startOrientation
        }
    }
    var endOrientation: CircleAngle {
        switch self {
        case .linear(let path): path.endOrientation
        case .circular(let path): path.endOrientation
        case .compound(let path): path.endOrientation
        }
    }
    var length: Distance {
        switch self {
        case .linear(let path): path.length
        case .circular(let path): path.length
        case .compound(let path): path.length
        }
    }
    var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): path.range
        case .circular(let path): path.range
        case .compound(let path): path.range
        }
    }
    var reverse: SomeFinitePath {
        switch self {
        case .linear(let path): .linear(path.reverse)
        case .circular(let path): .circular(path.reverse)
        case .compound(let path): .compound(path.reverse)
        }
    }
    var finitePathType: FinitePathType {
        switch self {
        case .linear: .linear
        case .circular: .circular
        case .compound: .compound
        }
    }
    
    func offsetLeft(by d: Distance) -> SomeFinitePath? {
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
    
    func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): path.point(at: x)
        case .circular(let path): path.point(at: x)
        case .compound(let path): path.point(at: x)
        }
    }
    
    func orientation(at x: Position) -> CircleAngle? {
        switch self {
        case .linear(let path): path.orientation(at: x)
        case .circular(let path): path.orientation(at: x)
        case .compound(let path): path.orientation(at: x)
        }
    }
    
    func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.forwardAtomicPathType(at: x)
        case .circular(let path): path.forwardAtomicPathType(at: x)
        case .compound(let path): path.forwardAtomicPathType(at: x)
        }
    }
    
    func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        switch self {
        case .linear(let path): path.backwardAtomicPathType(at: x)
        case .circular(let path): path.backwardAtomicPathType(at: x)
        case .compound(let path): path.backwardAtomicPathType(at: x)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): path.closestPointOnPath(from: p)
        case .circular(let path): path.closestPointOnPath(from: p)
        case .compound(let path): path.closestPointOnPath(from: p)
        }
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): path.pointsOnPath(atDistance: d, from: p)
        case .compound(let path): path.pointsOnPath(atDistance: d, from: p)
        }
    }
    
    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): path.firstPointOnPath(atDistance: d, after: x)
        case .compound(let path): path.firstPointOnPath(atDistance: d, after: x)
        }
    }
    
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): path.lastPointOnPath(atDistance: d, before: x)
        case .compound(let path): path.lastPointOnPath(atDistance: d, before: x)
        }
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): path.split(at: x)
        case .circular(let path): path.split(at:x)
        case .compound(let path): path.split(at:x)
        }
    }
    
    static func combine(_ a: SomeFinitePath, _ b: SomeFinitePath) -> SomeFinitePath? {
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
    
    var atomic: AtomicFinitePath? {
        switch self {
        case .linear(let path): .linear(path)
        case .circular(let path): .circular(path)
        case .compound: nil
        }
    }
    
}

struct Loop: Path {
    let underlying: SomeFinitePath
    var start: Point { underlying.start }
    var end: Point { underlying.end }
    var startOrientation: CircleAngle { underlying.startOrientation }
    var endOrientation: CircleAngle { underlying.endOrientation }
    var length: Distance { Distance(Float64.infinity) }
    var range: ClosedRange<Position> {
        Position(-Float64.infinity)...Position(Float64.infinity) }
    var reverse: Loop { Loop(underlying: underlying.reverse)! }
    
    func offsetLeft(by d: Distance) -> Loop? {
        guard let offsetUnderlying = underlying.offsetLeft(by: d) else {
            return nil
        }
        return Loop(underlying: offsetUnderlying)
    }
    
    func normalize(_ x: Position) -> Position {
        normalizeWithDelta(x).normalized
    }
    
    private func normalizeWithDelta(_ x: Position) -> (normalized: Position,
                                                            delta: Distance) {
        var delta = 0.0.m
        while x + delta < 0.0.m {
            delta += underlying.length
        }
        while x + delta >= underlying.length {
            delta -= underlying.length
        }
        return (x + delta, delta)
    }
    
    func point(at x: Position) -> Point? {
        underlying.point(at: normalize(x))
    }

    func orientation(at x: Position) -> CircleAngle? {
        underlying.orientation(at: normalize(x))
    }
    
    func forwardAtomicPathType(at x: Position) -> AtomicPathType? {
        underlying.forwardAtomicPathType(at: normalize(x))
    }
    
    func backwardAtomicPathType(at x: Position) -> AtomicPathType? {
        let normalizedX = normalize(x)
        if normalizedX == 0.0.m {
            return underlying.backwardAtomicPathType(at: underlying.length)
        } else {
            return underlying.backwardAtomicPathType(at: normalizedX)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        underlying.closestPointOnPath(from: p)
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        underlying.pointsOnPath(atDistance: d, from: p)
    }
    
    func firstPointOnPath(atDistance d: Distance,
                          after minGlobal: Position) -> Position? {
        let (x, delta) = normalizeWithDelta(minGlobal)
        if let result = underlying.firstPointOnPath(atDistance: d,
                                                    after: x) {
            return result - delta
        } else if let result = underlying.pointsOnPath(atDistance: d,
                                                       from: underlying.point(at: x)!).first {
            return result - delta + underlying.length
        } else {
            return nil
        }
    }
    
    func lastPointOnPath(atDistance d: Distance, before maxGlobal: Position) -> Position? {
        let (x, delta) = normalizeWithDelta(maxGlobal)
        if let result = underlying.lastPointOnPath(atDistance: d, before: x) {
            return result - delta
        } else if let result = underlying.pointsOnPath(atDistance: d,
                                                       from: underlying.point(at: x)!).last {
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
