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
    init(mapPointAtViewCenter: Point, mapScale: CGFloat) {
        self.mapPointAtViewCenter = mapPointAtViewCenter
        self.mapScale = mapScale
    }

    let mapPointAtViewCenter: Point
    let mapScale: CGFloat
    let style: Base.Style = .light

    func toMapDistance(viewDistance: CGFloat) -> Distance {
        Distance(viewDistance / mapScale)
    }

    func toMapPoint(viewPoint: CGPoint) -> Point {
        mapPointAtViewCenter
            + Point(
                x: Position(viewPoint.x / mapScale),
                y: Position(viewPoint.y / mapScale))
    }

    func toMapSize(viewSize: CGSize) -> Size {
        Size(
            width: Distance(viewSize.width / mapScale), height: Distance(viewSize.height / mapScale)
        )
    }

    func toMapRect(viewRect: CGRect) -> Rect {
        Rect(
            origin: toMapPoint(viewPoint: viewRect.origin),
            size: toMapSize(viewSize: viewRect.size))
    }

    func toViewAngle(_ angle: Angle) -> CGFloat { angle.withoutUnit }

    func toViewDistance(_ distance: Distance) -> CGFloat {
        mapScale * distance.withoutUnit
    }

    func toViewPoint(_ mapPoint: Point) -> CGPoint {
        CGPoint(
            x: mapScale * (mapPoint - mapPointAtViewCenter).x.withoutUnit,
            y: mapScale * (mapPoint - mapPointAtViewCenter).y.withoutUnit)
    }

    func toViewSize(_ mapSize: Size) -> CGSize {
        CGSize(
            width: mapScale * mapSize.width.withoutUnit,
            height: mapScale * mapSize.height.withoutUnit)
    }

    func toViewRect(_ mapRect: Rect) -> CGRect {
        CGRect(origin: toViewPoint(mapRect.origin), size: toViewSize(mapRect.size))
    }
}
