//
//  PositionMapping.swift
//  Base
//
//  Created by Arne Philipeit on 12/19/24.
//

import Foundation

public struct PositionMapping: Equatable {
    public enum Direction: Equatable {
        case positive, negative

        public var opposite: Direction {
            switch self {
            case .positive: .negative
            case .negative: .positive
            }
        }
    }

    public let validOldRange: ClosedRange<Position>
    private let offset: Position
    public let direction: Direction
    public var validNewRange: ClosedRange<Position> { uncheckedNewRange(for: validOldRange) }

    public init(for validRange: ClosedRange<Position>) {
        self.validOldRange = validRange
        self.offset = 0.0.m
        self.direction = .positive
    }

    private init(validOldRange: ClosedRange<Position>, offset: Position, direction: Direction) {
        self.validOldRange = validOldRange
        self.offset = offset
        self.direction = direction
    }

    public func shift(by delta: Distance) -> PositionMapping {
        let newOffset = offset + delta
        return PositionMapping(
            validOldRange: validOldRange,
            offset: newOffset,
            direction: direction)
    }

    public var inverted: PositionMapping {
        let newOffset =
            switch direction {
            case .positive: validNewRange.upperBound
            case .negative: validNewRange.lowerBound
            }
        return PositionMapping(
            validOldRange: validOldRange,
            offset: newOffset,
            direction: direction.opposite)
    }

    public func shortenAtStart(to newLength: Distance) -> PositionMapping {
        precondition(newLength <= validOldRange.length())
        let newValidOldRange =
            switch direction {
            case .positive: (validOldRange.upperBound - newLength)...validOldRange.upperBound
            case .negative: validOldRange.lowerBound...(validOldRange.lowerBound + newLength)
            }
        let newOffset =
            switch direction {
            case .positive: offset + (validOldRange.length() - newLength)
            case .negative: offset
            }
        return PositionMapping(
            validOldRange: newValidOldRange,
            offset: newOffset,
            direction: direction)
    }

    public func shortenAtEnd(to newLength: Distance) -> PositionMapping {
        precondition(newLength <= validOldRange.length())
        let newValidOldRange =
            switch direction {
            case .positive: validOldRange.lowerBound...(validOldRange.lowerBound + newLength)
            case .negative: (validOldRange.upperBound - newLength)...validOldRange.upperBound
            }
        let newOffset =
            switch direction {
            case .positive: offset
            case .negative: offset - (validOldRange.length() - newLength)
            }
        return PositionMapping(
            validOldRange: newValidOldRange,
            offset: newOffset,
            direction: direction)
    }

    public func newPosition(for oldPosition: Position) -> Position? {
        if validOldRange.contains(oldPosition) {
            uncheckedNewPosition(for: oldPosition)
        } else {
            nil
        }
    }

    public enum RangeResult: Equatable {
        case none
        case partial(ClosedRange<Position>)
        case full(ClosedRange<Position>)
    }

    public func newRange(for oldRange: ClosedRange<Position>) -> RangeResult {
        if oldRange.lowerBound >= validOldRange.upperBound
            || oldRange.upperBound <= validOldRange.lowerBound
        {
            .none
        } else if validOldRange.contains(oldRange.lowerBound)
            && validOldRange.contains(oldRange.upperBound)
        {
            .full(uncheckedNewRange(for: oldRange))
        } else {
            .partial(uncheckedNewRange(for: oldRange.clamped(to: validOldRange)))
        }
    }

    private func uncheckedNewPosition(for oldPosition: Position) -> Position {
        switch direction {
        case .positive:
            offset + (oldPosition - validOldRange.lowerBound)
        case .negative:
            offset - (oldPosition - validOldRange.lowerBound)
        }
    }

    private func uncheckedNewRange(for oldRange: ClosedRange<Position>) -> ClosedRange<Position> {
        let a = uncheckedNewPosition(for: oldRange.lowerBound)
        let b = uncheckedNewPosition(for: oldRange.upperBound)
        return switch direction {
        case .positive: a...b
        case .negative: b...a
        }
    }

}

extension FinitePath {
    public var withMapping: FinitePathAndPositionMapping<Self> {
        FinitePathAndPositionMapping(self)
    }
}

public struct FinitePathAndPositionMapping<P: FinitePath>: Equatable {
    public let path: P
    public let mapping: PositionMapping

    internal init(_ path: P) {
        self.path = path
        self.mapping = PositionMapping(for: path.range)
    }

    internal init(_ path: P, _ mapping: PositionMapping) {
        self.path = path
        self.mapping = mapping
    }

    public var reverse: FinitePathAndPositionMapping {
        FinitePathAndPositionMapping(path.reverse, mapping.inverted)
    }

    public func split(at x: Position) -> (
        FinitePathAndPositionMapping<SomeFinitePath>,
        FinitePathAndPositionMapping<SomeFinitePath>
    )? {
        guard let (pathA, pathB) = path.split(at: x) else { return nil }
        let mappingA = mapping.shortenAtEnd(to: pathA.length)
        let mappingB = mapping.shortenAtStart(to: pathB.length).shift(by: -pathA.length)
        return (
            FinitePathAndPositionMapping<SomeFinitePath>(pathA, mappingA),
            FinitePathAndPositionMapping<SomeFinitePath>(pathB, mappingB)
        )
    }

    public func split(at x1: Position, and x2: Position) -> (
        FinitePathAndPositionMapping<SomeFinitePath>,
        FinitePathAndPositionMapping<SomeFinitePath>,
        FinitePathAndPositionMapping<SomeFinitePath>
    )? {
        guard let (pathA, pathB, pathC) = path.split(at: x1, and: x2) else { return nil }
        let mappingA = mapping.shortenAtEnd(to: pathA.length)
        let mappingB = mapping.shortenAtEnd(to: pathA.length + pathB.length)
            .shortenAtStart(to: pathB.length)
            .shift(by: -pathA.length)
        let mappingC = mapping.shortenAtStart(to: pathC.length)
            .shift(by: -pathA.length - pathB.length)
        return (
            FinitePathAndPositionMapping<SomeFinitePath>(pathA, mappingA),
            FinitePathAndPositionMapping<SomeFinitePath>(pathB, mappingB),
            FinitePathAndPositionMapping<SomeFinitePath>(pathC, mappingC)
        )
    }

    public static func combine(
        _ a: FinitePathAndPositionMapping,
        _ b: FinitePathAndPositionMapping
    ) -> (P, PositionMapping, PositionMapping)? {
        guard let path = P.combine(a.path, b.path) else { return nil }
        return (path, a.mapping, b.mapping.shift(by: a.path.length))
    }

    public static func combine(_ partsAndMappings: [FinitePathAndPositionMapping]) -> (
        P, [PositionMapping]
    )? {
        guard let path = P.combine(partsAndMappings.map { $0.path }) else { return nil }
        var offset = 0.0.m
        var mappings: [PositionMapping] = []
        for partAndMapping in partsAndMappings {
            mappings.append(partAndMapping.mapping.shift(by: offset))
            offset += partAndMapping.path.length
        }
        return (path, mappings)
    }

}
