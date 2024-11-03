//
//  DrawContext+CGContext.swift
//  Base
//
//  Created by Arne Philipeit on 10/26/24.
//

import CoreGraphics
import Foundation

extension DrawContext {

    public func saveGState() {
        cgContext.saveGState()
    }

    public func restoreGState() {
        cgContext.restoreGState()
    }

    public func clip() {
        cgContext.clip()
    }

    public func move(to p: Point) {
        cgContext.move(to: viewContext.toViewPoint(p))
    }

    public func addLine(to p: Point) {
        cgContext.addLine(to: viewContext.toViewPoint(p))
    }

    public func addArc(
        center: Point, radius: Distance, startAngle: Angle, endAngle: Angle, clockwise: Bool
    ) {
        cgContext.addArc(
            center: viewContext.toViewPoint(center),
            radius: viewContext.toViewDistance(radius),
            startAngle: viewContext.toViewAngle(startAngle),
            endAngle: viewContext.toViewAngle(endAngle),
            clockwise: clockwise)
    }

    public func addQuadCurve(to end: Point, control: Point) {
        cgContext.addQuadCurve(
            to: viewContext.toViewPoint(end),
            control: viewContext.toViewPoint(control))
    }

    public func closePath() {
        cgContext.closePath()
    }

    public func setLineWidth(_ width: Distance) {
        cgContext.setLineWidth(viewContext.toViewDistance(width))
    }

    public func setStrokeColor(_ color: Color) {
        cgContext.setStrokeColor(color.cgColor)
    }

    public func setStrokeColor(_ color: CGColor) {
        cgContext.setStrokeColor(color)
    }

    public func setLineDash(phase: Distance, lengths: [Distance]) {
        cgContext.setLineDash(
            phase: viewContext.toViewDistance(phase),
            lengths: lengths.map { viewContext.toViewDistance($0) })
    }

    public func setFillColor(_ color: Color) {
        cgContext.setFillColor(color.cgColor)
    }

    public func setFillColor(_ color: CGColor) {
        cgContext.setFillColor(color)
    }

    public func strokePath() {
        cgContext.strokePath()
    }

    public func strokeCircle(at mapCenter: Point, radius mapRadius: Distance) {
        let viewCenter = viewContext.toViewPoint(mapCenter)
        let viewRadius = viewContext.toViewDistance(mapRadius)
        let viewRect = CGRect(
            x: viewCenter.x - viewRadius,
            y: viewCenter.y - viewRadius,
            width: 2.0 * viewRadius,
            height: 2.0 * viewRadius)
        cgContext.strokeEllipse(in: viewRect)
    }

    public func drawPath(using mode: CGPathDrawingMode) {
        cgContext.drawPath(using: mode)
    }

    public func drawLinearGradient(
        _ gradient: CGGradient, start: Point, end: Point, options: CGGradientDrawingOptions
    ) {
        cgContext.drawLinearGradient(
            gradient, start: viewContext.toViewPoint(start), end: viewContext.toViewPoint(end),
            options: options)
    }

    public func fillPath() {
        cgContext.fillPath()
    }

    public func fill(_ rect: Rect) {
        cgContext.move(to: viewContext.toViewPoint(rect.corners[0]))
        cgContext.addLine(to: viewContext.toViewPoint(rect.corners[1]))
        cgContext.addLine(to: viewContext.toViewPoint(rect.corners[2]))
        cgContext.addLine(to: viewContext.toViewPoint(rect.corners[3]))
        cgContext.fillPath()
    }

    public func fillCircle(at mapCenter: Point, radius mapRadius: Distance) {
        let viewCenter = viewContext.toViewPoint(mapCenter)
        let viewRadius = viewContext.toViewDistance(mapRadius)
        let viewRect = CGRect(
            x: viewCenter.x - viewRadius,
            y: viewCenter.y - viewRadius,
            width: 2.0 * viewRadius,
            height: 2.0 * viewRadius)
        cgContext.fillEllipse(in: viewRect)
    }

    public func draw(_ image: CGImage, in rect: Rect, byTiling tiling: Bool) {
        // TODO: implement
        // cgContext.draw(image, in: viewContext.toViewRect(rect), byTiling: tiling)
    }

}
