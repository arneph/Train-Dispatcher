//
//  CompoundPath.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

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

    public static func isDistance(
        between pathA: CompoundPath,
        and pathB: CompoundPath,
        above minDistance: Distance
    ) -> Bool {
        for componentA in pathA.components {
            for componentB in pathB.components {
                if !AtomicFinitePath.isDistance(
                    between: componentA,
                    and: componentB,
                    above: minDistance)
                {
                    return false
                }
            }
        }
        return true
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
