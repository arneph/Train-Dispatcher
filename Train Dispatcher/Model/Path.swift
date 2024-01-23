//
//  Path.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/19/24.
//

import Foundation

fileprivate let minDistance = 0.01.m
fileprivate let minAngle = 0.1.deg

let epsilon = Distance(1e-6)

func isApproximatelyEqual(x: Position, y: Position) -> Bool { abs(x - y) < epsilon }
func isApproximatelyLessThan(x: Position, y: Position) -> Bool { x - y < -epsilon }
func isApproximatelyGreaterThan(x: Position, y: Position) -> Bool { x - y > +epsilon }

func isApproximatelyInRange(x: Position,
                            range: ClosedRange<Position>) -> Bool {
    range.lowerBound <= x + epsilon && x - epsilon <= range.upperBound
}

struct PointAndOrientation {
    let point: Point
    let orientation: Angle
}

enum AtomicPathType {
    case linear, circular
}

enum FinitePathType {
    case linear, circular, compound
    
    var atomicPathType: AtomicPathType? {
        switch self {
        case .linear: return .linear
        case .circular: return .circular
        case .compound: return nil
        }
    }
    
    init(_ atomicPathType: AtomicPathType) {
        switch atomicPathType {
        case .linear: self = .linear
        case .circular: self = .circular
        }
    }
}

struct ClosestPathPointInfo {
    enum AtomicPathInfo {
        case singleAtomicPath(AtomicPathType)
        case twoAtomicPathsConnection(AtomicPathType, AtomicPathType)
    }
    enum SpecialCase {
        case no, start, end
    }
    
    let distance: Distance
    let x: Position
    let atomicPathInfo: AtomicPathInfo
    let specialCase: SpecialCase
}

protocol Path: Codable, CodeRepresentable {
    var reverse: Self { get }
    
    func offsetLeft(by: Distance) -> Self?
    func offsetRight(by: Distance) -> Self?
    
    func normalize(_ x: Position) -> Position
    
    func point(at x: Position) -> Point?
    func orientation(at x: Position) -> Angle?
    func pointAndOrientation(at x: Position) -> PointAndOrientation?
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position]
}

extension Path {
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
    var startOrientation: Angle { get }
    var endOrientation: Angle { get }
    var length: Distance { get }
    var range: ClosedRange<Position> { get }
    
    var startPointAndOrientation: PointAndOrientation { get }
    var endPointAndOrientation: PointAndOrientation { get }
    
    var finitePathType: FinitePathType { get }
    
    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position?
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position?
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)?
    static func combine(_ a: Self, _ b: Self) -> Self?
}

extension FinitePath {
    var startPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: start, orientation: startOrientation)
    }
    var endPointAndOrientation: PointAndOrientation {
        PointAndOrientation(point: end, orientation: endOrientation)
    }
}

func canConnect(_ a: PointAndOrientation, _ b: PointAndOrientation) -> Bool {
    distance(a.point, b.point) < minDistance && absDiff(a.orientation, b.orientation) <= minAngle
}

struct LinearPath: FinitePath {
    let start: Point
    let end: Point
    var orientation: Angle { angle(from: start, to: end) }
    var startOrientation: Angle { orientation }
    var endOrientation: Angle { orientation }
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
    
    func offsetRight(by d: Distance) -> LinearPath? {
        LinearPath(start: start + d ** right, end: end + d ** right)!
    }
    
    func normalize(_ x: Position) -> Position { x }
    
    func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        let progress = x / length
        return start + (end - start) * progress
    }
    
    func orientation(at x: Position) -> Angle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        return orientation
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
        let c = distance²(start, from) - pow2(r)
        let d = pow2(b) - 4.0 * a * c
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
        return pointsOnPath(atDistance: d, from: point(at: min)!).filter{ min <= $0 }.first
    }
    
    func lastPointOnPath(atDistance d: Distance,
                         before max: Position) -> Position? {
        return pointsOnPath(atDistance: d, from: point(at: max)!).filter{ $0 <= max }.last
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
    
    static let name: String = "LinearPath"
    private static let labels: [String] = [startLabel, endLabel]
    private static let startLabel: String = "start"
    private static let endLabel: String = "end"
    
    static func parseCode(with scanner: Scanner) -> LinearPath? {
        parseStruct(name: name, scanner: scanner) {
            guard let (start, end): (Point, Point) = parseArguments(labels: labels,
                                                                    scanner: scanner) else {
                return nil
            }
            return LinearPath(start: start, end: end)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: LinearPath.name, printer: printer) {
            print(labelsAndArguments: [(LinearPath.startLabel, start),
                                       (LinearPath.endLabel, end)],
                  printer: printer)
        }
    }
    
}

struct CircularPath: FinitePath {
    let center: Point
    let radius: Distance
    var startOrientation: Angle {
        !clockwise ? startAngle + Angle(Float64.pi * 0.5)
                   : startAngle - Angle(Float64.pi * 0.5)
    }
    var endOrientation: Angle {
        !clockwise ? endAngle + Angle(Float64.pi * 0.5)
                   : endAngle - Angle(Float64.pi * 0.5)
    }
    let startAngle: Angle
    let endAngle: Angle
    var deltaAngle: AngleDiff {
        clamp(angle: endAngle - startAngle, min: !clockwise ? 0.0.deg : -360.0.deg)
    }
    let clockwise: Bool
    var start: Point {
        center + radius ** startAngle
    }
    var end: Point {
        center + radius ** endAngle
    }
    var length: Distance {
        radius * angleAsScale(abs(deltaAngle))
    }
    var range: ClosedRange<Position> { Position(0.0)...length }
    var reverse: CircularPath {
        CircularPath(center: center,
                     radius: radius,
                     startAngle: endAngle,
                     endAngle: startAngle,
                     clockwise: !clockwise)!
    }
    var finitePathType: FinitePathType { .circular }
    
    func offsetLeft(by d: Distance) -> CircularPath? {
        CircularPath(center: center,
                     radius: radius + (clockwise ? +d : -d),
                     startAngle: startAngle,
                     endAngle: endAngle,
                     clockwise: clockwise)!
    }
    
    func offsetRight(by d: Distance) -> CircularPath? {
        CircularPath(center: center,
                     radius: radius + (clockwise ? -d : +d),
                     startAngle: startAngle,
                     endAngle: endAngle,
                     clockwise: clockwise)!
    }
    
    func normalize(_ x: Position) -> Position { x }
    
    private func clampForPath(angle a: Angle) -> Angle {
        clamp(angle: a, min: !clockwise ? startAngle : endAngle)
    }
    
    private func isOnPath(clampedAngle: Angle) -> Bool {
        if !clockwise {
            return startAngle <= clampedAngle && clampedAngle <= endAngle
        } else {
            return startAngle >= clampedAngle && clampedAngle >= endAngle
        }
    }
    
    func point(at x: Position) -> Point? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        let angle = deltaAngle * (x / length)
        return center + radius ** (startAngle + angle)
    }
    
    func orientation(at x: Position) -> Angle? {
        if !isApproximatelyInRange(x: x, range: range) {
            return nil
        }
        let angle = deltaAngle * (x / length)
        if !clockwise {
            return startAngle + angle + Angle(Float64.pi * 0.5)
        } else {
            return startAngle + angle - Angle(Float64.pi * 0.5)
        }
    }
    
    func closestPointOnPath(from: Point) -> ClosestPathPointInfo {
        let distToStart = distance(from, start)
        let distToEnd = distance(from, end)
        let angle = clampForPath(angle: angle(from: center, to: from))
        if isOnPath(clampedAngle: angle) {
            let distToCenter = distance(from, center)
            let distToProjectedPoint = abs(distToCenter - radius)
            let x: Position = radius * angleAsScale(abs(angle - startAngle))
            if distToProjectedPoint < distToStart &&
                distToProjectedPoint < distToEnd {
                return ClosestPathPointInfo(distance: distToProjectedPoint, 
                                            x: x,
                                            atomicPathInfo: .singleAtomicPath(.circular),
                                            specialCase: .no)
            }
        }
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
        if distToCenter < abs(radius - distToPoints) ||
            distToCenter > radius + distToPoints {
            return []
        }
        let baseAngle = clampForPath(angle: angle(from: center, to: p))
        if distToCenter == abs(radius - distToPoints) ||
            distToCenter == radius + distToPoints {
            return isOnPath(clampedAngle: baseAngle)
                 ? [radius * angleAsScale(abs(baseAngle - startAngle))] : []
        }
        let l = (pow2(radius) + pow2(distToCenter) - pow2(distToPoints))
                / (2.0 * distToCenter)
        let angleOffset = Angle(acos(l / radius))
        let angle1 = clampForPath(angle: baseAngle - angleOffset)
        let angle2 = clampForPath(angle: baseAngle + angleOffset)
        return [angle1, angle2]
            .filter{ isOnPath(clampedAngle: $0) }
            .map{ radius * angleAsScale(abs($0 - startAngle)) }
            .sorted()
    }
    
    func firstPointOnPath(atDistance d: Distance,
                          after min: Position) -> Position? {
        return pointsOnPath(atDistance: d, from: point(at: min)!).filter{ min <= $0 }.first
    }
    
    func lastPointOnPath(atDistance d: Distance,
                         before max: Position) -> Position? {
        return pointsOnPath(atDistance: d, from: point(at: max)!).filter{ $0 <= max }.last
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        if x <= 0.0.m || x >= length {
            return nil
        }
        let orientation = orientation(at: x)!
        return (.circular(CircularPath(center: center,
                                       radius: radius,
                                       startAngle: startAngle,
                                       endAngle: orientation,
                                       clockwise: clockwise)!),
                .circular(CircularPath(center: center,
                                       radius: radius,
                                       startAngle: orientation,
                                       endAngle: endAngle,
                                       clockwise: clockwise)!))
    }
    
    static func combine(_ a: CircularPath, _ b: CircularPath) -> CircularPath? {
        guard a.center == b.center,
              a.radius == b.radius,
              a.clockwise == b.clockwise,
              a.endAngle == b.startAngle else {
            return nil
        }
        return CircularPath(center: a.center,
                            radius: a.radius,
                            startAngle: a.startAngle,
                            endAngle: b.endAngle,
                            clockwise: a.clockwise)
    }
    
    init?(center: Point,
          radius: Distance,
          startAngle: Angle,
          endAngle: Angle,
          clockwise: Bool) {
        if radius < minDistance || absDiff(startAngle, endAngle) < minAngle {
            return nil
        }
        self.center = center
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
    }
    
    fileprivate static let name: String = "CircularPath"
    private static let labels: [String] =
        [centerLabel, radiusLabel, startAngleLabel, endAngleLabel, clockwiseLabel]
    private static let centerLabel: String = "center"
    private static let radiusLabel: String = "radius"
    private static let startAngleLabel: String = "startAngle"
    private static let endAngleLabel: String = "endAngle"
    private static let clockwiseLabel: String = "clockwise"
        
    static func parseCode(with scanner: Scanner) -> CircularPath? {
        parseStruct(name: name, scanner: scanner) {
            guard let (center, radius, startAngle, endAngle, clockwise):
                    (Point, Distance, Angle, Angle, Bool) = parseArguments(labels: labels,
                                                                           scanner: scanner) else {
                return nil
            }
            return CircularPath(center: center,
                                radius: radius,
                                startAngle: startAngle,
                                endAngle: endAngle,
                                clockwise: clockwise)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: CircularPath.name, printer: printer) {
            print(labelsAndArguments: [(CircularPath.centerLabel, center),
                                       (CircularPath.radiusLabel, radius),
                                       (CircularPath.startAngleLabel, startAngle),
                                       (CircularPath.endAngleLabel, endAngle),
                                       (CircularPath.clockwiseLabel, clockwise)],
                  printer: printer)
        }
    }
    
}

enum AtomicFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)
    
    var start: Point {
        switch self {
        case .linear(let path): return path.start
        case .circular(let path): return path.start
        }
    }
    var end: Point {
        switch self {
        case .linear(let path): return path.end
        case .circular(let path): return path.end
        }
    }
    var startOrientation: Angle {
        switch self {
        case .linear(let path): return path.startOrientation
        case .circular(let path): return path.startOrientation
        }
    }
    var endOrientation: Angle {
        switch self {
        case .linear(let path): return path.endOrientation
        case .circular(let path): return path.endOrientation
        }
    }
    var length: Distance {
        switch self {
        case .linear(let path): return path.length
        case .circular(let path): return path.length
        }
    }
    var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): return path.range
        case .circular(let path): return path.range
        }
    }
    var reverse: AtomicFinitePath {
        switch self {
        case .linear(let path): return .linear(path.reverse)
        case .circular(let path): return .circular(path.reverse)
        }
    }
    var finitePathType: FinitePathType {
        switch self {
        case .linear: return .linear
        case .circular: return .circular
        }
    }
    
    func offsetLeft(by d: Distance) -> AtomicFinitePath? {
        switch self {
        case .linear(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                return .linear(offsetPath)
            } else {
                return nil
            }
        case .circular(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                return .circular(offsetPath)
            } else {
                return nil
            }
        }
    }
    
    func offsetRight(by d: Distance) -> AtomicFinitePath? {
        switch self {
        case .linear(let path):
            if let offsetPath = path.offsetRight(by: d) {
                return .linear(offsetPath)
            } else {
                return nil
            }
        case .circular(let path):
            if let offsetPath = path.offsetRight(by: d) {
                return .circular(offsetPath)
            } else {
                return nil
            }
        }
    }
    
    func normalize(_ x: Position) -> Position {
        switch self {
        case .linear(let path): return path.normalize(x)
        case .circular(let path): return path.normalize(x)
        }
    }
    
    func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): return path.point(at: x)
        case .circular(let path): return path.point(at: x)
        }
    }
    
    func orientation(at x: Position) -> Angle? {
        switch self {
        case .linear(let path): return path.orientation(at: x)
        case .circular(let path): return path.orientation(at: x)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): return path.closestPointOnPath(from: p)
        case .circular(let path): return path.closestPointOnPath(from: p)
        }
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): return path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): return path.pointsOnPath(atDistance: d, from: p)
        }
    }
    
    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): return path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): return path.firstPointOnPath(atDistance: d, after: x)
        }
    }
    
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): return path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): return path.lastPointOnPath(atDistance: d, before: x)
        }
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): return path.split(at: x)
        case .circular(let path): return path.split(at:x)
        }
    }
    
    static func combine(_ a: AtomicFinitePath, _ b: AtomicFinitePath) -> AtomicFinitePath? {
        switch (a, b) {
        case (.linear(let a), .linear(let b)):
            if let path = LinearPath.combine(a, b) {
                return .linear(path)
            } else {
                return nil
            }
        case (.circular(let a), .circular(let b)):
            if let path = CircularPath.combine(a, b) {
                return .circular(path)
            } else {
                return nil
            }
        case (.linear, .circular), (.circular, .linear):
            return nil
        }
    }
    
    static func parseCode(with scanner: Scanner) -> AtomicFinitePath? {
        switch scanner.peek() {
        case .identifier(LinearPath.name):
            guard let path = LinearPath.parseCode(with: scanner) else { return nil }
            return .linear(path)
        case .identifier(CircularPath.name):
            guard let path = CircularPath.parseCode(with: scanner) else { return nil }
            return .circular(path)
        default:
            return nil
        }
    }
    
    func printCode(with printer: Printer) {
        switch self {
        case .linear(let path): return path.printCode(with: printer)
        case .circular(let path): return path.printCode(with: printer)
        }
    }
}

struct CompoundPath: FinitePath {
    let components: [AtomicFinitePath]
    var start: Point { components.first!.start }
    var end: Point { components.last!.end }
    var startOrientation: Angle { components.first!.startOrientation }
    var endOrientation: Angle { components.last!.endOrientation }
    var length: Distance { components.map{$0.length}.reduce(Distance(0.0), +) }
    var range: ClosedRange<Position> { Position(0.0)...length }
    var reverse: CompoundPath {
        CompoundPath(checkedComponents: components.map{$0.reverse}.reversed())!
    }
    var finitePathType: FinitePathType { .compound }
    
    func offsetLeft(by d: Distance) -> CompoundPath? {
        let offsetAtomicFinitePaths = components.compactMap({ $0.offsetLeft(by: d) })
        guard offsetAtomicFinitePaths.count == components.count else {
            return nil
        }
        return CompoundPath(checkedComponents: offsetAtomicFinitePaths)
    }
    
    func offsetRight(by d: Distance) -> CompoundPath? {
        let offsetAtomicFinitePaths = components.compactMap({ $0.offsetRight(by: d) })
        guard offsetAtomicFinitePaths.count == components.count else {
            return nil
        }
        return CompoundPath(checkedComponents: offsetAtomicFinitePaths)
    }
    
    func normalize(_ x: Position) -> Position { x }
    
    private struct Context {
        let globalStart: Position
        let globalEnd: Position
        var globalRange: ClosedRange<Position> { globalStart...globalEnd }
        
        func toLocal(_ xGlobal: Position) -> Position { xGlobal - globalStart }
        func toGlobal(_ xLocal: Position) -> Position { globalStart + xLocal }
    }
    private var contexts: [Context] {
        var contexts: [Context] = []
        var globalStart = Position(0.0)
        for component in components {
            let globalEnd = globalStart + component.length
            contexts.append(Context(globalStart: globalStart, globalEnd: globalEnd))
            globalStart = globalEnd
        }
        return contexts
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
    
    func orientation(at xGlobal: Position) -> Angle? {
        guard let (component, xLocal) = component(at: xGlobal) else {
            return nil
        }
        return component.orientation(at: xLocal)
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
            return SomeFinitePath(paths.first!)
        } else {
            return .compound(CompoundPath(checkedComponents: paths)!)
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
    
    init?(components: [AtomicFinitePath]) {
        if components.count < 2 {
            return nil
        }
        for index in 0...components.count - 2 {
            if distance(components[index].end,
                        components[index + 1].start) >= Distance(0.01) {
                return nil
            }
            var diff = abs(components[index].endOrientation -
                           components[index + 1].startOrientation)
            while diff >= 360.deg { diff -= 360.0.deg }
            if diff > Angle(0.01) {
                return nil
            }
        }
        self.init(checkedComponents: components)
    }
    
    fileprivate init!(checkedComponents components: [AtomicFinitePath]) {
        self.components = components
    }
        
    fileprivate static let name: String = "CompoundPath"
    private static let componentsLabel: String = "components"
    
    static func parseCode(with scanner: Scanner) -> CompoundPath? {
        parseStruct(name: name, scanner: scanner) {
            guard let components: [AtomicFinitePath] = parseArgument(label: componentsLabel,
                                                                     scanner: scanner) else {
                return nil
            }
            return CompoundPath(components: components)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: CompoundPath.name, printer: printer) {
            print(label: CompoundPath.componentsLabel, argument: components, printer: printer)
        }
    }
}

enum SomeFinitePath: FinitePath {
    case linear(LinearPath)
    case circular(CircularPath)
    case compound(CompoundPath)
    
    var start: Point {
        switch self {
        case .linear(let path): return path.start
        case .circular(let path): return path.start
        case .compound(let path): return path.start
        }
    }
    var end: Point {
        switch self {
        case .linear(let path): return path.end
        case .circular(let path): return path.end
        case .compound(let path): return path.end
        }
    }
    var startOrientation: Angle {
        switch self {
        case .linear(let path): return path.startOrientation
        case .circular(let path): return path.startOrientation
        case .compound(let path): return path.startOrientation
        }
    }
    var endOrientation: Angle {
        switch self {
        case .linear(let path): return path.endOrientation
        case .circular(let path): return path.endOrientation
        case .compound(let path): return path.endOrientation
        }
    }
    var length: Distance {
        switch self {
        case .linear(let path): return path.length
        case .circular(let path): return path.length
        case .compound(let path): return path.length
        }
    }
    var range: ClosedRange<Position> {
        switch self {
        case .linear(let path): return path.range
        case .circular(let path): return path.range
        case .compound(let path): return path.range
        }
    }
    var reverse: SomeFinitePath {
        switch self {
        case .linear(let path): return .linear(path.reverse)
        case .circular(let path): return .circular(path.reverse)
        case .compound(let path): return .compound(path.reverse)
        }
    }
    var finitePathType: FinitePathType {
        switch self {
        case .linear: return .linear
        case .circular: return .circular
        case .compound: return .compound
        }
    }
    
    func offsetLeft(by d: Distance) -> SomeFinitePath? {
        switch self {
        case .linear(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                return .linear(offsetPath)
            } else {
                return nil
            }
        case .circular(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                return .circular(offsetPath)
            } else {
                return nil
            }
        case .compound(let path):
            if let offsetPath = path.offsetLeft(by: d) {
                return .compound(offsetPath)
            } else {
                return nil
            }
        }
    }
    
    func offsetRight(by d: Distance) -> SomeFinitePath? {
        switch self {
        case .linear(let path):
            if let offsetPath = path.offsetRight(by: d) {
                return .linear(offsetPath)
            } else {
                return nil
            }
        case .circular(let path):
            if let offsetPath = path.offsetRight(by: d) {
                return .circular(offsetPath)
            } else {
                return nil
            }
        case .compound(let path):
            if let offsetPath = path.offsetRight(by: d) {
                return .compound(offsetPath)
            } else {
                return nil
            }
        }
    }
    
    func normalize(_ x: Position) -> Position {
        switch self {
        case .linear(let path): return path.normalize(x)
        case .circular(let path): return path.normalize(x)
        case .compound(let path): return path.normalize(x)
        }
    }
    
    func point(at x: Position) -> Point? {
        switch self {
        case .linear(let path): return path.point(at: x)
        case .circular(let path): return path.point(at: x)
        case .compound(let path): return path.point(at: x)
        }
    }
    
    func orientation(at x: Position) -> Angle? {
        switch self {
        case .linear(let path): return path.orientation(at: x)
        case .circular(let path): return path.orientation(at: x)
        case .compound(let path): return path.orientation(at: x)
        }
    }
    
    func closestPointOnPath(from p: Point) -> ClosestPathPointInfo {
        switch self {
        case .linear(let path): return path.closestPointOnPath(from: p)
        case .circular(let path): return path.closestPointOnPath(from: p)
        case .compound(let path): return path.closestPointOnPath(from: p)
        }
    }
    
    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
        switch self {
        case .linear(let path): return path.pointsOnPath(atDistance: d, from: p)
        case .circular(let path): return path.pointsOnPath(atDistance: d, from: p)
        case .compound(let path): return path.pointsOnPath(atDistance: d, from: p)
        }
    }
    
    func firstPointOnPath(atDistance d: Distance, after x: Position) -> Position? {
        switch self {
        case .linear(let path): return path.firstPointOnPath(atDistance: d, after: x)
        case .circular(let path): return path.firstPointOnPath(atDistance: d, after: x)
        case .compound(let path): return path.firstPointOnPath(atDistance: d, after: x)
        }
    }
    
    func lastPointOnPath(atDistance d: Distance, before x: Position) -> Position? {
        switch self {
        case .linear(let path): return path.lastPointOnPath(atDistance: d, before: x)
        case .circular(let path): return path.lastPointOnPath(atDistance: d, before: x)
        case .compound(let path): return path.lastPointOnPath(atDistance: d, before: x)
        }
    }
    
    func split(at x: Position) -> (SomeFinitePath, SomeFinitePath)? {
        switch self {
        case .linear(let path): return path.split(at: x)
        case .circular(let path): return path.split(at:x)
        case .compound(let path): return path.split(at:x)
        }
    }
    
    static func combine(_ a: SomeFinitePath, _ b: SomeFinitePath) -> SomeFinitePath? {
        switch (a, b) {
        case (.linear(let a), .linear(let b)):
            if let path = LinearPath.combine(a, b) {
                return .linear(path)
            } else {
                return nil
            }
        case (.circular(let a), .circular(let b)):
            if let path = CircularPath.combine(a, b) {
                return .circular(path)
            } else {
                return nil
            }
        case (.linear(let a), .circular(let b)):
            if let path = CompoundPath(components: [.linear(a), .circular(b)]) {
                return .compound(path)
            } else {
                return nil
            }
        case (.circular(let a), .linear(let b)):
            if let path = CompoundPath(components: [.circular(a), .linear(b)]) {
                return .compound(path)
            } else {
                return nil
            }
        case (.linear(let a), .compound(let b)):
            if let path = CompoundPath.combine(.linear(a), b) {
                return .compound(path)
            } else {
                return nil
            }
        case (.circular(let a), .compound(let b)):
            if let path = CompoundPath.combine(.circular(a), b) {
                return .compound(path)
            } else {
                return nil
            }
        case (.compound(let a), .linear(let b)):
            if let path = CompoundPath.combine(a, .linear(b)) {
                return .compound(path)
            } else {
                return nil
            }
        case (.compound(let a), .circular(let b)):
            if let path = CompoundPath.combine(a, .circular(b)) {
                return .compound(path)
            } else {
                return nil
            }
        case (.compound(let a), .compound(let b)):
            if let path = CompoundPath.combine(a, b) {
                return .compound(path)
            } else {
                return nil
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
        case .linear(let path): return .linear(path)
        case .circular(let path): return .circular(path)
        case .compound: return nil
        }
    }
    
    static func parseCode(with scanner: Scanner) -> SomeFinitePath? {
        switch scanner.peek() {
        case .identifier(LinearPath.name):
            guard let path = LinearPath.parseCode(with: scanner) else { return nil }
            return .linear(path)
        case .identifier(CircularPath.name):
            guard let path = CircularPath.parseCode(with: scanner) else { return nil }
            return .circular(path)
        case .identifier(CompoundPath.name):
            guard let path = CompoundPath.parseCode(with: scanner) else { return nil }
            return .compound(path)
        default:
            return nil
        }
    }
    
    func printCode(with printer: Printer) {
        switch self {
        case .linear(let path): return path.printCode(with: printer)
        case .circular(let path): return path.printCode(with: printer)
        case .compound(let path): return path.printCode(with: printer)
        }
    }
}

struct Loop: Path {
    
    let underlying: SomeFinitePath
    var start: Point { underlying.start }
    var end: Point { underlying.end }
    var startOrientation: Angle { underlying.startOrientation }
    var endOrientation: Angle { underlying.endOrientation }
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
    
    func offsetRight(by d: Distance) -> Loop? {
        guard let offsetUnderlying = underlying.offsetRight(by: d) else {
            return nil
        }
        return Loop(underlying: offsetUnderlying)
    }
    
    func normalize(_ x: Position) -> Position {
        normalizeWithDelta(x).normalized
    }
    
    private func normalizeWithDelta(_ x: Position) -> (normalized: Position,
                                                            delta: Distance) {
        var delta = Distance(0.0)
        while x + delta < Position(0.0) {
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

    func orientation(at x: Position) -> Angle? {
        underlying.orientation(at: normalize(x))
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
    
    private static let name: String = "Loop"
    private static let underlyingLabel: String = "underlying"
    
    static func parseCode(with scanner: Scanner) -> Loop? {
        parseStruct(name: name, scanner: scanner) {
            guard let underlying: SomeFinitePath = parseArgument(label: underlyingLabel,
                                                                 scanner: scanner) else {
                return nil
            }
            return Loop(underlying: underlying)
        }
    }
    
    func printCode(with printer: Printer) {
        printStruct(name: Loop.name, printer: printer) {
            print(label: Loop.underlyingLabel,
                  argument: underlying,
                  printer: printer)
        }
    }
}
