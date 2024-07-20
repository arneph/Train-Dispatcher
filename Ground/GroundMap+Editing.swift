//
//  GroundMap+Editing.swift
//  Ground
//
//  Created by Arne Philipeit on 6/2/24.
//

import Base
import Foundation

extension GroundMap {

    public func paintCircle(
        at center: Point,
        withDiameter diameter: Distance,
        inColor newColor: Color
    ) {
        guard diameter > 0.0.m else { return }
        updatePixels(in: Rect.square(around: center, length: diameter)) { (point, oldColor) in
            distance(center, point) <= diameter / 2.0 ? newColor : oldColor
        }
    }

    public func paintLine(
        from start: Point,
        to end: Point,
        withWidth width: Distance,
        inColor newColor: Color
    ) {
        guard start != end && width > 0.0.m else { return }
        let line = Line(through: start, and: end)!
        updatePixels(
            in: Rect(p1: start, p2: end).insetBy(
                dx: -width / 2.0,
                dy: -width / 2.0)
        ) { (point, oldColor) in
            let projection = line.closestPoint(to: point)
            let included =
                distance(point, projection) <= width / 2.0
                && distance(start, projection) + distance(end, projection)
                    == distance(start, end)
            return included ? newColor : oldColor
        }
    }

}
