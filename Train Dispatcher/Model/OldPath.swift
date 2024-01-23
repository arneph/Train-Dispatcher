//
//  Path.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/27/23.
//

import Foundation
import CoreGraphics
//
//enum EncodedFinitePath: Codable, CodeRepresentable {
//    case linear(LinearPath)
//    case circular(CircularPath)
//    case compound(CompoundPath)
//    
//    var underlying: FinitePath {
//        switch self {
//        case .linear(let path): return path
//        case .circular(let path): return path
//        case .compound(let path): return path
//        }
//    }
//    
//    init(_ underlying: FinitePath) {
//        if let path = underlying as? LinearPath {
//            self = .linear(path)
//        } else if let path = underlying as? CircularPath {
//            self = .circular(path)
//        } else if let path = underlying as? CompoundPath {
//            self = .compound(path)
//        } else {
//            fatalError("Unexpected FinitePath type")
//        }
//    }
//    
//    static func parseCode(with scanner: Scanner) -> EncodedFinitePath? {
//        switch scanner.peek() {
//        case .identifier(LinearPath.name):
//            guard let linear = LinearPath.parseCode(with: scanner) else { return nil }
//            return EncodedFinitePath(linear)
//        case .identifier(CircularPath.name):
//            guard let circular = CircularPath.parseCode(with: scanner) else { return nil }
//            return EncodedFinitePath(circular)
//        case .openBracket:
//            guard let compound = CompoundPath.parseCode(with: scanner) else { return nil }
//            return EncodedFinitePath(compound)
//        default:
//            return nil
//        }
//    }
//    
//    func printCode(with printer: Printer) {
//        underlying.printCode(with: printer)
//    }
//
//}
//
//enum EncodedAtomicFinitePath: Codable, CodeRepresentable {
//    case linear(LinearPath)
//    case circular(CircularPath)
//    
//    var underlying: AtomicFinitePath {
//        switch self {
//        case .linear(let path): return path
//        case .circular(let path): return path
//        }
//    }
//    
//    init(_ underlying: AtomicFinitePath) {
//        if let path = underlying as? LinearPath {
//            self = .linear(path)
//        } else if let path = underlying as? CircularPath {
//            self = .circular(path)
//        } else {
//            fatalError("Unexpected AtomicFinitePath type")
//        }
//    }
//    
//    static func parseCode(with scanner: Scanner) -> EncodedAtomicFinitePath? {
//        switch scanner.peek() {
//        case .identifier(LinearPath.name):
//            guard let linear = LinearPath.parseCode(with: scanner) else { return nil }
//            return EncodedAtomicFinitePath(linear)
//        case .identifier(CircularPath.name):
//            guard let circular = CircularPath.parseCode(with: scanner) else { return nil }
//            return EncodedAtomicFinitePath(circular)
//        default:
//            return nil
//        }
//    }
//    
//    func printCode(with printer: Printer) {
//        underlying.printCode(with: printer)
//    }
//    
//}

//let epsilon = Distance(1e-6)
//
//func isApproximatelyEqual(x: Position, y: Position) -> Bool { abs(x - y) < epsilon }
//func isApproximatelyLessThan(x: Position, y: Position) -> Bool { x - y < -epsilon }
//func isApproximatelyGreaterThan(x: Position, y: Position) -> Bool { x - y > +epsilon }
//
//func isApproximatelyInRange(x: Position,
//                            range: ClosedRange<Position>) -> Bool {
//    range.lowerBound <= x + epsilon && x - epsilon <= range.upperBound
//}
//
//struct CompoundPath: FinitePath {
//    let components: [any AtomicFinitePath]
//    var start: Point { components.first!.start }
//    var end: Point { components.last!.end }
//    var startOrientation: Angle { components.first!.startOrientation }
//    var endOrientation: Angle { components.last!.endOrientation }
//    var length: Distance { components.map{$0.length}.reduce(Distance(0.0), +) }
//    var range: ClosedRange<Position> { Position(0.0)...length }
//    var reverse: CompoundPath { CompoundPath(components: components.map{$0.reverse}.reversed())! }
//    
//    func offsetLeft(by d: Distance) -> CompoundPath? {
//        let offsetComponents = components.compactMap({ $0.offsetLeft(by: d) })
//        guard offsetComponents.count == components.count else {
//            return nil
//        }
//        return CompoundPath(components: offsetComponents)
//    }
//    
//    func offsetRight(by d: Distance) -> CompoundPath? {
//        let offsetComponents = components.compactMap({ $0.offsetRight(by: d) })
//        guard offsetComponents.count == components.count else {
//            return nil
//        }
//        return CompoundPath(components: offsetComponents)
//    }
//    
//    func normalize(_ x: Position) -> Position { x }
//    
//    private struct ComponentContext {
//        let component: AtomicFinitePath
//        let xGlobalStart: Position
//        let xGlobalEnd: Position
//        var xGlobalRange: ClosedRange<Position> { xGlobalStart...xGlobalEnd }
//    }
//    private var componentContexts: [ComponentContext] {
//        var contexts: [ComponentContext] = []
//        var xGlobalStart = Position(0.0)
//        for component in components {
//            let xGlobalEnd = xGlobalStart + component.length
//            contexts.append(ComponentContext(component: component,
//                                             xGlobalStart: xGlobalStart,
//                                             xGlobalEnd: xGlobalEnd))
//            xGlobalStart = xGlobalEnd
//        }
//        return contexts
//    }
//    
//    func componentAt(_ xGlobal: Position) -> (component: AtomicFinitePath,
//                                              xLocal: Position)? {
//        for cc in componentContexts {
//            if isApproximatelyInRange(x: xGlobal, range: cc.xGlobalRange) {
//                return (cc.component, xGlobal - cc.xGlobalStart)
//            }
//        }
//        return nil
//    }
//    
//    private func indexAndComponentAt(_ xGlobal: Position) -> (index: Int,
//                                                              component: AtomicFinitePath,
//                                                              xLocal: Position)? {
//        for (index, cc) in componentContexts.enumerated() {
//            if isApproximatelyInRange(x: xGlobal, range: cc.xGlobalRange) {
//                return (index, cc.component, xGlobal - cc.xGlobalStart)
//            }
//        }
//        return nil
//    }
//    
//    func pointAt(_ x: Position) -> Point? {
//        guard let (component, xLocal) = componentAt(x) else {
//            return nil
//        }
//        return component.pointAt(xLocal)
//    }
//    
//    func orientationAt(_ x: Position) -> Angle? {
//        guard let (component, xLocal) = componentAt(x) else {
//            return nil
//        }
//        return component.orientationAt(xLocal)
//    }
//    
//    func closestPointOnPath(from: Point) -> ClosestPointInfo {
//        componentContexts.map{ (cc: ComponentContext) -> ClosestPointInfo in
//            let localPoint = cc.component.closestPointOnPath(from: from)
//            return ClosestPointInfo(distance: localPoint.distance,
//                                          x: cc.xGlobalStart + localPoint.x)
//        }.min(by: { $0.distance < $1.distance })!
//    }
//    
//    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
//        componentContexts
//            .flatMap{ (cc) -> [Position] in
//                cc.component
//                  .pointsOnPath(atDistance: d, from: p)
//                  .map{ cc.xGlobalStart + $0 }}
//            .reduce([]) { xs, x in isApproximatelyEqual(x: xs.last ?? Position(-1.0), y: x)
//                                   ? xs : (xs + [x]) }
//    }
//    
//    func firstPointOnPath(atDistance d: Distance,
//                          after minGlobal: Position) -> Position? {
//        var p: Point? = nil
//        for cc in componentContexts {
//            if isApproximatelyLessThan(x: cc.xGlobalEnd, y: minGlobal) {
//               continue
//            }
//            let minLocal = minGlobal - cc.xGlobalStart
//            if p == nil {
//                p = cc.component.pointAt(minLocal)
//            }
//            for xLocal in cc.component.pointsOnPath(atDistance: d, from: p!) {
//                if xLocal >= minLocal {
//                    return xLocal + cc.xGlobalStart
//                }
//            }
//        }
//        return nil
//    }
//    
//    func lastPointOnPath(atDistance d: Distance,
//                         before maxGlobal: Position) -> Position? {
//        var p: Point? = nil
//        for cc in componentContexts.reversed() {
//            if isApproximatelyGreaterThan(x: cc.xGlobalStart, y: maxGlobal) {
//                continue
//            }
//            let maxLocal = maxGlobal - cc.xGlobalStart
//            if p == nil {
//                p = cc.component.pointAt(maxLocal)
//            }
//            for xLocal in cc.component.pointsOnPath(atDistance: d, from: p!) {
//                if xLocal <= maxLocal {
//                    return xLocal + cc.xGlobalStart
//                }
//            }
//        }
//        return nil
//    }
//    
//    func split(at x: Position) -> (FinitePath, FinitePath)? {
//        if x <= 0.0.m || x >= length {
//            return nil
//        }
//        guard let (index, component, xLocal) = indexAndComponentAt(x) else {
//            return nil
//        } 
//        let componentsA: [any AtomicFinitePath]
//        let componentsB: [any AtomicFinitePath]
//        if xLocal == 0.0.m {
//            componentsA = Array(components.prefix(upTo: index))
//            componentsB = Array(components.suffix(from: index))
//        } else if xLocal == component.length {
//            componentsA = Array(components.prefix(upTo: index + 1))
//            componentsB = Array(components.suffix(from: index + 1))
//        } else {
//            let (a, b) = component.split(at: xLocal)! as! (AtomicFinitePath, AtomicFinitePath)
//            componentsA = Array<any AtomicFinitePath>(components.prefix(upTo: index) + [a])
//            componentsB = Array<any AtomicFinitePath>([b] + components.suffix(from: index + 1))
//        }
//        return (combine(paths: componentsA), combine(paths: componentsB))
//    }
//    
//    init?(components: [any AtomicFinitePath]) {
//        if components.count < 2 {
//            return nil
//        }
//        for index in 0...components.count - 2 {
//            if distance(components[index].end,
//                        components[index + 1].start) >= Distance(0.01) {
//                return nil
//            }
//            var diff = abs(components[index].endOrientation -
//                           components[index + 1].startOrientation)
//            while diff >= 360.deg { diff -= 360.0.deg }
//            if diff > Angle(0.01) {
//                return nil
//            }
//        }
//        self.components = components
//    }
//    
//    private enum CodingKeys: String, CodingKey {
//        case components
//    }
//    
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        self.components = try values.decode([EncodedAtomicFinitePath].self,
//                                            forKey: .components).map{ $0.underlying }
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var values = encoder.container(keyedBy: CodingKeys.self)
//        try values.encode(components.map{ EncodedAtomicFinitePath($0) }, forKey: .components)
//    }
//    
//    fileprivate static let name: String = "CompoundPath"
//    private static let componentsLabel: String = "components"
//    
//    static func parseCode(with scanner: Scanner) -> CompoundPath? {
////        parseStruct(name: name, scanner: scanner) {
////            guard let components: [EncodedAtomicFinitePath] = parseArgument(label: componentsLabel,
////                                                                            scanner: scanner) else {
////                return nil
////            }
////            return CompoundPath(components: components.map{ $0.underlying })
////        }
//        guard let components = [EncodedAtomicFinitePath].parseCode(with: scanner) else {
//            return nil
//        }
//        return CompoundPath(components: components.map{ $0.underlying })
//    }
//    
//    func printCode(with printer: Printer) {
////        printStruct(name: CompoundPath.name, printer: printer) {
////            print(label: CompoundPath.componentsLabel,
////                  argument: components.map{ EncodedFinitePath($0) },
////                  printer: printer)
////        }
//        components.map{ EncodedFinitePath($0) }.printCode(with: printer)
//    }
//
//}

//private func combine(first: FinitePath, second: FinitePath) -> FinitePath? {
//    switch first {
//    case let first as LinearPath:
//        guard let second = second as? LinearPath,
//              first.end == second.start,
//              first.orientation == second.orientation else {
//            return nil
//        }
//        return LinearPath(start: first.start, end: second.end)!
//    case let first as CircularPath:
//        guard let second = second as? CircularPath,
//              first.center == second.center,
//              first.radius == second.radius,
//              first.clockwise == second.clockwise,
//              first.endAngle == second.startAngle else {
//                  return nil
//              }
//        return CircularPath(center: first.center,
//                            radius: first.radius,
//                            startAngle: first.startAngle,
//                            endAngle: second.endAngle,
//                            clockwise: first.clockwise)
//    default:
//        return nil
//    }
//}

//private func combine(paths: [any AtomicFinitePath]) -> FinitePath {
//    if paths.count == 1 {
//        return paths.first!
//    } else {
//        return CompoundPath(components: paths)!
//    }
//}

//func reduce(components originalComponents: [any FinitePath]) -> [any FinitePath] {
//    var components: [any FinitePath] = []
//    for component in originalComponents {
//        if let compound = component as? CompoundPath {
//            components.append(contentsOf: compound.components)
//        } else {
//            components.append(component)
//        }
//    }
//    var index = 0
//    while index < components.count - 1 {
//        let first = components[index]
//        let second = components[index + 1]
//        guard let combined = combine(first: first, second: second) else {
//            index += 1
//            continue
//        }
//        components[index] = combined
//        components.remove(at: index + 1)
//    }
//    return components
//}

//struct Loop: Path {
//    let underlying: FinitePath
//    var start: Point { underlying.start }
//    var end: Point { underlying.end }
//    var startOrientation: Angle { underlying.startOrientation }
//    var endOrientation: Angle { underlying.endOrientation }
//    var length: Distance { Distance(Float64.infinity) }
//    var range: ClosedRange<Position> {
//        Position(-Float64.infinity)...Position(Float64.infinity) }
//    var reverse: Loop { Loop(underlying: underlying.reverse)! }
//    
//    func offsetLeft(by d: Distance) -> Loop? {
//        guard let offsetUnderlying = underlying.offsetLeft(by: d) else {
//            return nil
//        }
//        return Loop(underlying: offsetUnderlying)
//    }
//    
//    func offsetRight(by d: Distance) -> Loop? {
//        guard let offsetUnderlying = underlying.offsetRight(by: d) else {
//            return nil
//        }
//        return Loop(underlying: offsetUnderlying)
//    }
//    
//    func normalize(_ x: Position) -> Position {
//        normalizeWithDelta(x).normalized
//    }
//    
//    private func normalizeWithDelta(_ x: Position) -> (normalized: Position,
//                                                            delta: Distance) {
//        var delta = Distance(0.0)
//        while x + delta < Position(0.0) {
//            delta += underlying.length
//        }
//        while x + delta >= underlying.length {
//            delta -= underlying.length
//        }
//        return (x + delta, delta)
//    }
//    
//    func pointAt(_ x: Position) -> Point? {
//        underlying.pointAt(normalize(x))
//    }
//
//    func orientationAt(_ x: Position) -> Angle? {
//        underlying.orientationAt(normalize(x))
//    }
//    
//    func closestPointOnPath(from p: Point) -> ClosestPointInfo {
//        underlying.closestPointOnPath(from: p)
//    }
//    
//    func pointsOnPath(atDistance d: Distance, from p: Point) -> [Position] {
//        underlying.pointsOnPath(atDistance: d, from: p)
//    }
//    
//    func firstPointOnPath(atDistance d: Distance,
//                          after minGlobal: Position) -> Position? {
//        let (x, delta) = normalizeWithDelta(minGlobal)
//        if let result = underlying.firstPointOnPath(atDistance: d,
//                                                    after: x) {
//            return result - delta
//        } else if let result = underlying.pointsOnPath(atDistance: d,
//                                                       from: underlying.pointAt(x)!).first {
//            return result - delta + underlying.length
//        } else {
//            return nil
//        }
//    }
//    
//    func lastPointOnPath(atDistance d: Distance, before maxGlobal: Position) -> Position? {
//        let (x, delta) = normalizeWithDelta(maxGlobal)
//        if let result = underlying.lastPointOnPath(atDistance: d, before: x) {
//            return result - delta
//        } else if let result = underlying.pointsOnPath(atDistance: d,
//                                                       from: underlying.pointAt(x)!).last {
//            return result - delta - underlying.length
//        } else {
//            return nil
//        }
//    }
//    
//    init?(underlying: FinitePath) {
//        if underlying.start != underlying.end {
//            return nil
//        }
//        self.underlying = underlying
//    }
//    
//    private enum CodingKeys: String, CodingKey {
//        case underlying
//    }
//    
//    init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        self.underlying = try values.decode(EncodedFinitePath.self, forKey: .underlying).underlying
//    }
//    
//    func encode(to encoder: Encoder) throws {
//        var values = encoder.container(keyedBy: CodingKeys.self)
//        try values.encode(EncodedFinitePath(underlying), forKey: .underlying)
//    }
//    
//    private static let name: String = "Loop"
//    private static let underlyingLabel: String = "underlying"
//    
//    static func parseCode(with scanner: Scanner) -> Loop? {
//        parseStruct(name: name, scanner: scanner) {
//            guard let underlying: EncodedFinitePath = parseArgument(label: underlyingLabel,
//                                                                    scanner: scanner) else {
//                return nil
//            }
//            return Loop(underlying: underlying.underlying)
//        }
//    }
//    
//    func printCode(with printer: Printer) {
//        printStruct(name: Loop.name, printer: printer) {
//            print(label: Loop.underlyingLabel,
//                  argument: EncodedFinitePath(underlying),
//                  printer: printer)
//        }
//    }
//    
//}

//func atomicFinitePaths(of path: Path) -> [AtomicFinitePath] {
//    if let atomic = path as? AtomicFinitePath {
//        return [atomic]
//    } else if let compound = path as? CompoundPath {
//        return compound.components
//    } else if let loop = path as? Loop {
//        return atomicFinitePaths(of: loop.underlying)
//    } else {
//        assertionFailure("Unexpected Path")
//        return []
//    }
//}
//
//func atomicFinitePaths(of paths: [Path]) -> [AtomicFinitePath] {
//    paths.flatMap{ atomicFinitePaths(of: $0) }
//}

//func trace(path: FinitePath,
//           _ cgContext: CGContext,
//           _ viewContext: ViewContext) {
//    cgContext.move(to: viewContext.toViewPoint(path.start))
//    
//    if let path = path as? CompoundPath {
//        trace(compoundPath: path, cgContext, viewContext)
//    } else if let path = path as? AtomicFinitePath {
//        trace(atomicPath: path, cgContext, viewContext)
//    } else {
//        assertionFailure("unexpected FinitePath")
//    }
//}
//
//fileprivate func trace(compoundPath path: CompoundPath,
//                       _ cgContext: CGContext,
//                       _ viewContext: ViewContext) {
//    for component in path.components {
//        trace(atomicPath: component, cgContext, viewContext)
//    }
//}
//
//fileprivate func trace(atomicPath path: AtomicFinitePath,
//                       _ cgContext: CGContext,
//                       _ viewContext: ViewContext) {
//    if let path = path as? LinearPath {
//        trace(linearPath: path, cgContext, viewContext)
//    } else if let path = path as? CircularPath {
//        trace(circularPath: path, cgContext, viewContext)
//    } else {
//        assertionFailure("unexpected AtomicFinitePath")
//    }
//}
//
//fileprivate func trace(linearPath path: LinearPath,
//                       _ cgContext: CGContext,
//                       _ viewContext: ViewContext) {
//    cgContext.addLine(to: viewContext.toViewPoint(path.end))
//}
//
//fileprivate func trace(circularPath path: CircularPath,
//                       _ cgContext: CGContext,
//                       _ viewContext: ViewContext) {
//    cgContext.addArc(center: viewContext.toViewPoint(path.center),
//                     radius: viewContext.toViewDistance(path.radius),
//                     startAngle: viewContext.toViewAngle(path.startAngle),
//                     endAngle: viewContext.toViewAngle(path.endAngle),
//                     clockwise: path.clockwise)
//}
