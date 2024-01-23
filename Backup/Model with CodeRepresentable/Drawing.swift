//
//  Drawable.swift
//  Train Dispatcher
//
//  Created by Arne Philipeit on 11/29/23.
//

import Foundation
import CoreGraphics

enum Style {
    case light, dark
}

protocol ViewContext {
    var style: Style { get }
    var mapScale: CGFloat { get }
    
    func toMapPoint(viewPoint: CGPoint) -> Point
    func toMapSize(viewSize: CGSize) -> Size
    func toMapRect(viewRect: CGRect) -> Rect
    
    func toViewAngle(_ angle: Angle) -> CGFloat
    func toViewDistance(_ distance: Distance) -> CGFloat
    
    func toViewPoint(_ mapPoint: Point) -> CGPoint
    func toViewSize(_ mapSize: Size) -> CGSize
    func toViewRect(_ mapRect: Rect) -> CGRect
}

protocol Drawable {
    func draw(_ cgContext: CGContext, _ viewContext: ViewContext)
}

func trace(path: LinearPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addLine(to: viewContext.toViewPoint(path.end))
}

func trace(path: CircularPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    cgContext.addArc(center: viewContext.toViewPoint(path.center),
                     radius: viewContext.toViewDistance(path.radius),
                     startAngle: viewContext.toViewAngle(path.startAngle),
                     endAngle: viewContext.toViewAngle(path.endAngle),
                     clockwise: path.clockwise)
}

func trace(path: CompoundPath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    cgContext.move(to: viewContext.toViewPoint(path.start))
    for component in path.components {
        switch component {
        case .linear(let component):
            cgContext.addLine(to: viewContext.toViewPoint(component.end))
        case .circular(let component):
            cgContext.addArc(center: viewContext.toViewPoint(component.center),
                             radius: viewContext.toViewDistance(component.radius),
                             startAngle: viewContext.toViewAngle(component.startAngle),
                             endAngle: viewContext.toViewAngle(component.endAngle),
                             clockwise: component.clockwise)
        }
    }
}

func trace(path: AtomicFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    switch path {
    case .linear(let path):
        trace(path: path, cgContext, viewContext)
    case .circular(let path):
        trace(path: path, cgContext, viewContext)
    }
}

func trace(path: SomeFinitePath, _ cgContext: CGContext, _ viewContext: ViewContext) {
    switch path {
    case .linear(let path):
        trace(path: path, cgContext, viewContext)
    case .circular(let path):
        trace(path: path, cgContext, viewContext)
    case .compound(let path):
        trace(path: path, cgContext, viewContext)
    }
}

func trace(loop: Loop, _ cgContext: CGContext, _ viewContext: ViewContext) {
    trace(path: loop.underlying, cgContext, viewContext)
}
