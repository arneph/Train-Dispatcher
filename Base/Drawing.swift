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

public protocol Drawable {
    func draw(ctx: DrawContext)
}

public protocol ViewContext {
    var style: Style { get }
    var mapScale: CGFloat { get }

    func toMapAngle(viewAngle: CGFloat) -> Angle
    func toMapDistance(viewDistance: CGFloat) -> Distance
    func toMapPoint(viewPoint: CGPoint) -> Point

    func toViewAngle(_ angle: Angle) -> CGFloat
    func toViewDistance(_ distance: Distance) -> CGFloat
    func toViewPoint(_ mapPoint: Point) -> CGPoint
}

public struct DrawContext {
    internal let cgContext: CGContext
    internal let viewContext: ViewContext
    public let dirtyRect: Rect

    public init(cgContext: CGContext, viewContext: ViewContext, dirtyRect: Rect) {
        self.cgContext = cgContext
        self.viewContext = viewContext
        self.dirtyRect = dirtyRect
    }

    public var style: Style { viewContext.style }
    public var mapScale: Float64 { viewContext.mapScale }

    public func max(_ mapDistance: Distance, _ viewDistance: CGFloat) -> Distance {
        Base.max(mapDistance, viewContext.toMapDistance(viewDistance: viewDistance))
    }
}
