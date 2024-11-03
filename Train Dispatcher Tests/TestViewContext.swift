//
//  TestViewContext.swift
//  Train Dispatcher Tests
//
//  Created by Arne Philipeit on 3/26/24.
//

import Base
import CoreGraphics
import Foundation

class TestViewContext: ViewContext {
    init(mapPointAtViewCenter: Point, mapRotation: CircleAngle, mapScale: CGFloat) {
        self.mapPointAtViewCenter = mapPointAtViewCenter
        self.mapRotation = mapRotation
        self.mapScale = mapScale
    }

    let mapPointAtViewCenter: Point
    let mapRotation: CircleAngle
    let mapScale: CGFloat
    let style: Base.Style = .light

    func toMapAngle(viewAngle: CGFloat) -> Angle {
        mapRotation + Angle(viewAngle)
    }

    func toMapDistance(viewDistance: CGFloat) -> Distance {
        Distance(viewDistance / mapScale)
    }

    func toMapPoint(viewPoint: CGPoint) -> Point {
        let v = Direction(
            x: Position(viewPoint.x / mapScale),
            y: Position(viewPoint.y / mapScale))
        let (a, d) = angleAndLength(of: v)
        return mapPointAtViewCenter + d ** (mapRotation + a)
    }

    func toViewAngle(_ angle: Angle) -> CGFloat { angle.withoutUnit }

    func toViewDistance(_ distance: Distance) -> CGFloat {
        mapScale * distance.withoutUnit
    }

    func toViewPoint(_ mapPoint: Point) -> CGPoint {
        let (a, d) = angleAndLength(of: mapPoint - mapPointAtViewCenter)
        let v = d ** (a - mapRotation.asAngle)
        return CGPoint(
            x: mapScale * v.x.withoutUnit,
            y: mapScale * v.y.withoutUnit)
    }

}
