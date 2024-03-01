//
//  CircleAngle.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 1/31/24.
//

import Foundation

struct CircleAngle: Equatable,
                    Hashable,
                    Codable,
                    CustomStringConvertible,
                    CustomDebugStringConvertible,
                    CustomReflectable {
    private let value: Angle
    
    private static func clamp(_ a: Angle) -> Angle {
        var angle = a
        while angle < -180.0.deg { angle += 360.0.deg }
        while angle >= 180.0.deg { angle -= 360.0.deg }
        return angle
    }
    
    init(_ angle: Angle) {
        self.value = CircleAngle.clamp(angle)
    }
    
    var opposite: CircleAngle { CircleAngle(value + 180.0.deg) }
    
    var asAngle: Angle { value }
    var withoutUnit: Float64 { value.withoutUnit }
    
    static func + (lhs: CircleAngle, rhs: Angle) -> Angle {
        lhs.asAngle + rhs
    }
    
    static func - (lhs: CircleAngle, rhs: Angle) -> Angle {
        lhs.asAngle - rhs
    }
    
    static func == (lhs: CircleAngle, rhs: CircleAngle) -> Bool { absDiff(lhs, rhs) <  0.00001.deg }
    static func != (lhs: CircleAngle, rhs: CircleAngle) -> Bool { absDiff(lhs, rhs) >= 0.00001.deg }
    
    var description: String { asAngle.description }
    var debugDescription: String { asAngle.debugDescription }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}

func cos(_ orientation: CircleAngle) -> Float64 {
    cos(orientation.asAngle)
}

func sin(_ orientation: CircleAngle) -> Float64 {
    sin(orientation.asAngle)
}

func absDiff(_ a: CircleAngle, _ b: CircleAngle) -> AngleDiff {
    min(absDiff(a.asAngle, b.asAngle), 
        min(absDiff(a.asAngle, b.asAngle - 360.0.deg),
            absDiff(a.asAngle - 360.0.deg, b.asAngle)))
}

struct CircleRange: Equatable,
                    Hashable,
                    Codable,
                    CustomStringConvertible,
                    CustomDebugStringConvertible,
                    CustomReflectable {
    enum Direction: CustomStringConvertible, CustomDebugStringConvertible {
        case positive, negative

        var description: String {
            switch self {
            case .positive: "positive"
            case .negative: "negative"
            }
        }
        var debugDescription: String {
            switch self {
            case .positive: "positive"
            case .negative: "negative"
            }
        }
    }
    
    let start: CircleAngle
    let delta: AngleDiff
    var end: CircleAngle { CircleAngle(start + delta) }

    var middle: CircleAngle { CircleAngle(start + 0.5 * delta) }
    
    var absDelta: AngleDiff { abs(delta) }
    var direction: Direction { delta >= 0.0.deg ? .positive : .negative }
    var flipped: CircleRange { CircleRange(start: end, delta: -delta) }
    
    var startAngle: Angle { start.asAngle }
    var endAngle: Angle { end.asAngle }
    
    var hasNoExtent: Bool { absDelta == 0.0.deg }
    var hasFullExtent: Bool { absDelta == 360.0.deg }
    var withOppositeExtent: CircleRange {
        switch direction {
        case .positive: CircleRange(start: end, delta: +360.0.deg - delta)
        case .negative: CircleRange(start: end, delta: -360.0.deg - delta)
        }
    }
    
    func contains(_ orientation: CircleAngle) -> Bool {
        switch direction {
        case .positive:
            if endAngle >= startAngle {
                startAngle <= orientation.asAngle && orientation.asAngle <= endAngle
            } else {
                startAngle <= orientation.asAngle || orientation.asAngle <= endAngle
            }
        case .negative:
            if startAngle >= endAngle {
                endAngle <= orientation.asAngle && orientation.asAngle <= startAngle
            } else {
                endAngle <= orientation.asAngle || orientation.asAngle <= startAngle
            }
        }
    }
    
    // Returns the fraction of orientation between the start and end of the range, possibly > 1.0.
    func fraction(for orientation: CircleAngle) -> Float64 {
        CircleRange(start: start, end: orientation, direction: direction).delta / delta
    }
    
    func split(at a: CircleAngle) -> (CircleRange, CircleRange)? {
        if !contains(a) { return nil }
        return (CircleRange(start: start, end: a,   direction: direction),
                CircleRange(start: a,     end: end, direction: direction))
    }
    
    static func combine(_ a: CircleRange, _ b: CircleRange) -> CircleRange? {
        guard a.end == b.start, a.direction == b.direction else { return nil }
        return CircleRange(start: a.start, delta: a.delta + b.delta)
    }
    
    init(start: CircleAngle, delta: AngleDiff) {
        assert(-360.0.deg < delta && delta <= 360.0.deg)
        self.start = start
        self.delta = delta
    }
    
    init(start: CircleAngle, end: CircleAngle, direction: Direction) {
        switch direction {
        case .positive:
            let delta = start.asAngle <= end.asAngle ?
                        end.asAngle - start.asAngle :
                        end.asAngle + 360.0.deg - start.asAngle
            self.init(start: start, delta: delta)
        case .negative:
            let delta = end.asAngle <= start.asAngle ?
                        end.asAngle - start.asAngle :
                        end.asAngle - start.asAngle - 360.0.deg
            self.init(start: start, delta: delta)
        }
    }
    
    static func range(from base: Point, between a: Point, and b: Point) -> CircleRange {
        let alpha1 = CircleAngle(angle(from: base, to: a))
        let alpha2 = CircleAngle(angle(from: base, to: b))
        let range1 = CircleRange(start: alpha1, end: alpha2, direction: .positive)
        let range2 = CircleRange(start: alpha1, end: alpha2, direction: .negative)
        return range1.absDelta <= range2.absDelta ? range1 : range2
    }
    
    var description: String {
        if delta == 360.0.deg {
            start.description + " (full circle)"
        } else if delta == 0.0.deg {
            start.description + " (empty circle)"
        } else {
            start.description + "..." + end.description + " (" + direction.description + ")"
        }
    }
    var debugDescription: String {
        start.debugDescription + "..." + end.debugDescription +
        " (" + direction.debugDescription + ")"
    }
    var customMirror: Mirror { Mirror(reflecting: self.description) }
}
