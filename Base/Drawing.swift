//
//  Drawable.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import CoreGraphics
import Foundation

public enum Style {
    case light, dark
}

public protocol ViewContext {
    var style: Style { get }
    var mapScale: CGFloat { get }

    func toMapDistance(viewDistance: CGFloat) -> Distance

    func toMapPoint(viewPoint: CGPoint) -> Point
    func toMapSize(viewSize: CGSize) -> Size
    func toMapRect(viewRect: CGRect) -> Rect

    func toViewAngle(_ angle: Angle) -> CGFloat
    func toViewDistance(_ distance: Distance) -> CGFloat

    func toViewPoint(_ mapPoint: Point) -> CGPoint
    func toViewSize(_ mapSize: Size) -> CGSize
    func toViewRect(_ mapRect: Rect) -> CGRect
}

public protocol Drawable {
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext)
}

public func trace(path: LinearPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addLine(to: viewContext.toViewPoint(path.end))
}

public func trace(path: CircularPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addArc(
        center: viewContext.toViewPoint(path.center),
        radius: viewContext.toViewDistance(path.radius),
        startAngle: viewContext.toViewAngle(path.circleRange.startAngle),
        endAngle: viewContext.toViewAngle(path.circleRange.startAngle + path.circleRange.delta),
        clockwise: path.circleRange.direction == .negative)
}

public func trace(path: CompoundPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    for component in path.components {
        switch component {
        case .linear(let component):
            cgContext.addLine(to: viewContext.toViewPoint(component.end))
        case .circular(let component):
            cgContext.addArc(
                center: viewContext.toViewPoint(component.center),
                radius: viewContext.toViewDistance(component.radius),
                startAngle: viewContext.toViewAngle(component.circleRange.startAngle),
                endAngle: viewContext.toViewAngle(
                    component.circleRange.startAngle + component.circleRange.delta),
                clockwise: component.circleRange.direction == .negative)
        }
    }
}

public func trace(path: AtomicFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    switch path {
    case .linear(let path):
        trace(path: path, cgContext, viewContext)
    case .circular(let path):
        trace(path: path, cgContext, viewContext)
    }
}

public func trace(path: SomeFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    switch path {
    case .linear(let path):
        trace(path: path, cgContext, viewContext)
    case .circular(let path):
        trace(path: path, cgContext, viewContext)
    case .compound(let path):
        trace(path: path, cgContext, viewContext)
    }
}

public func trace(loop: Loop, _ cgContext: CGContext, _ viewContext: ViewContext) {
    trace(path: loop.underlying, cgContext, viewContext)
}
