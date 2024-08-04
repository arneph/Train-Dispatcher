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
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext, _ dirtyRect: Rect)
}

private func stroke(
    visiblePath path: LinearPath, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ width: Distance
) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addLine(to: viewContext.toViewPoint(path.end))
    cgContext.drawPath(using: .stroke)
}

public func stroke(
    path: LinearPath, _ cgContext: CGContext, _ viewContext: ViewContext, _ width: Distance,
    _ dirtyRect: Rect
) {
    for segment in path.segments(inRect: dirtyRect.insetBy(dx: -width, dy: -width)) {
        cgContext.move(to: viewContext.toViewPoint(path.point(at: segment.lowerBound)!))
        cgContext.addLine(to: viewContext.toViewPoint(path.point(at: segment.upperBound)!))
        cgContext.drawPath(using: .stroke)
    }
}

private func stroke(
    visiblePath path: CircularPath, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ width: Distance
) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addArc(
        center: viewContext.toViewPoint(path.center),
        radius: viewContext.toViewDistance(path.radius),
        startAngle: viewContext.toViewAngle(path.circleRange.startAngle),
        endAngle: viewContext.toViewAngle(path.circleRange.startAngle + path.circleRange.delta),
        clockwise: path.circleRange.direction == .negative)
    cgContext.drawPath(using: .stroke)
}

public func stroke(
    path: CircularPath, _ cgContext: CGContext, _ viewContext: ViewContext, _ width: Distance,
    _ dirtyRect: Rect
) {
    for segment in path.segments(inRect: dirtyRect.insetBy(dx: -width, dy: -width)) {
        cgContext.move(to: viewContext.toViewPoint(path.point(at: segment.lowerBound)!))
        cgContext.addArc(
            center: viewContext.toViewPoint(path.center),
            radius: viewContext.toViewDistance(path.radius),
            startAngle: viewContext.toViewAngle(path.toCircleAngle(segment.lowerBound).asAngle),
            endAngle: viewContext.toViewAngle(path.toCircleAngle(segment.upperBound).asAngle),
            clockwise: path.circleRange.direction == .negative)
        cgContext.drawPath(using: .stroke)
    }
}

private func stroke(
    visiblePath path: CompoundPath, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ width: Distance
) {
    for component in path.components {
        cgContext.move(to: viewContext.toViewPoint(component.start))
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
        cgContext.drawPath(using: .stroke)
    }
}

public func stroke(
    path: CompoundPath, _ cgContext: CGContext, _ viewContext: ViewContext, _ width: Distance,
    _ dirtyRect: Rect
) {
    for segment in path.segments(
        inRect: dirtyRect.insetBy(
            dx: -width,
            dy: -width))
    {
        guard let visiblePath = path.subPath(from: segment.lowerBound, to: segment.upperBound)
        else {
            continue
        }
        stroke(visiblePath: visiblePath, cgContext, viewContext, width)
    }
}

public func stroke(
    path: AtomicFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext, _ width: Distance,
    _ dirtyRect: Rect
) {
    switch path {
    case .linear(let path):
        stroke(path: path, cgContext, viewContext, width, dirtyRect)
    case .circular(let path):
        stroke(path: path, cgContext, viewContext, width, dirtyRect)
    }
}

private func stroke(
    visiblePath path: SomeFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ width: Distance
) {
    switch path {
    case .linear(let path):
        stroke(visiblePath: path, cgContext, viewContext, width)
    case .circular(let path):
        stroke(visiblePath: path, cgContext, viewContext, width)
    case .compound(let path):
        stroke(visiblePath: path, cgContext, viewContext, width)
    }
}

public func stroke(
    path: SomeFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext, _ width: Distance,
    _ dirtyRect: Rect
) {
    switch path {
    case .linear(let path):
        stroke(path: path, cgContext, viewContext, width, dirtyRect)
    case .circular(let path):
        stroke(path: path, cgContext, viewContext, width, dirtyRect)
    case .compound(let path):
        stroke(path: path, cgContext, viewContext, width, dirtyRect)
    }
}

public func stroke(
    loop: Loop, _ cgContext: CGContext, _ viewContext: ViewContext, width: Distance, dirtyRect: Rect
) {
    stroke(path: loop.underlying, cgContext, viewContext, width, dirtyRect)
}
