//
//  Rounding.swift
//  Base
//
//  Created by Arne Philipeit on 12/18/24.
//

import Foundation

internal let minDistance = 0.001.m
internal let minAngle = 0.001.deg

internal let epsilon = Distance(1e-6)

internal func isApproximatelyEqual(x: Position, y: Position) -> Bool { abs(x - y) < epsilon }
internal func isApproximatelyLessThan(x: Position, y: Position) -> Bool { x - y < -epsilon }
internal func isApproximatelyGreaterThan(x: Position, y: Position) -> Bool { x - y > +epsilon }

internal func isApproximatelyInRange(
    x: Position, range: ClosedRange<Position>
) -> Bool {
    range.lowerBound <= x + epsilon && x - epsilon <= range.upperBound
}
