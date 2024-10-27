//
//  SignalDrawing.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/12/24.
//

import Base
import CoreGraphics
import Foundation

public func draw(
    signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.saveGState()
    if viewContext.mapScale < 5.0 {
        drawWithLowDetail(signal, cgContext, viewContext, dirtyRect)
    } else {
        drawWithHighDetail(signal, cgContext, viewContext, dirtyRect)
    }
    cgContext.restoreGState()
}

private func drawWithLowDetail(
    _ signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    let possibleStates = 2
    let lightRadius = 0.5.m
    let lightRim = 0.15.m
    let boardRadius = lightRadius + lightRim
    let boardHeight = lightRim + possibleStates * (2 * lightRadius + lightRim)
    let supportHeight = 0.6.m
    let supportWidth = 0.3.m

    let forward = signal.orientation.asAngle
    let backward = signal.orientation.asAngle + 180.0.deg
    let left = signal.orientation.asAngle + 90.0.deg
    let right = signal.orientation.asAngle - 90.0.deg
    let p1 = signal.point + forward ** (0.5 * boardHeight - boardRadius) + left ** boardRadius
    let p2 = signal.point + backward ** (0.5 * boardHeight - boardRadius) + left ** boardRadius
    let p3 = signal.point + backward ** (0.5 * boardHeight - boardRadius) + right ** boardRadius
    let p4 = signal.point + forward ** (0.5 * boardHeight - boardRadius) + right ** boardRadius
    let p5 = signal.point + backward ** (0.5 * boardHeight + supportHeight)
    let p6 = signal.point + backward ** (0.5 * boardHeight + supportHeight) + left ** boardRadius
    let p7 = signal.point + backward ** (0.5 * boardHeight + supportHeight) + right ** boardRadius
    let c1 = signal.point + backward ** (0.5 * boardHeight - boardRadius)
    let c2 = signal.point + forward ** (0.5 * boardHeight - boardRadius)

    cgContext.setLineWidth(viewContext.toViewDistance(supportWidth))
    cgContext.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))

    cgContext.move(to: viewContext.toViewPoint(c1))
    cgContext.addLine(to: viewContext.toViewPoint(p5))
    cgContext.strokePath()

    cgContext.move(to: viewContext.toViewPoint(p6))
    cgContext.addLine(to: viewContext.toViewPoint(p7))
    cgContext.strokePath()

    cgContext.setLineWidth(viewContext.toViewDistance(0.02.m))
    cgContext.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    cgContext.setFillColor(CGColor(gray: 0.0, alpha: 1.0))

    cgContext.move(to: viewContext.toViewPoint(p1))
    cgContext.addLine(to: viewContext.toViewPoint(p2))
    cgContext.addArc(
        center: viewContext.toViewPoint(c1),
        radius: viewContext.toViewDistance(boardRadius),
        startAngle: left.withoutUnit,
        endAngle: right.withoutUnit,
        clockwise: false)
    cgContext.addLine(to: viewContext.toViewPoint(p3))
    cgContext.addLine(to: viewContext.toViewPoint(p4))
    cgContext.addArc(
        center: viewContext.toViewPoint(c2),
        radius: viewContext.toViewDistance(boardRadius),
        startAngle: right.withoutUnit,
        endAngle: left.withoutUnit,
        clockwise: false)
    cgContext.closePath()
    cgContext.fillPath()
    cgContext.strokePath()

    let greenLight =
        switch signal.state {
        case .fixed(.go): CGColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
        case .changing(let change):
            switch (change.previous, change.next) {
            case (.go, .go): CGColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 1.0)
            case (.go, _):
                CGColor(
                    red: 0.2, green: max(1.0 - 1.6 * change.progress, 0.2), blue: 0.2, alpha: 1.0)
            case (_, .go):
                CGColor(
                    red: 0.2, green: max(-0.6 + 1.6 * change.progress, 0.2), blue: 0.2, alpha: 1.0)
            default:
                CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            }
        default: CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    let redLight =
        switch signal.state {
        case .fixed(.blocked): CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
        case .changing(let change):
            switch (change.previous, change.next) {
            case (.blocked, .blocked): CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0)
            case (.blocked, _):
                CGColor(
                    red: max(1.0 - 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2, alpha: 1.0)
            case (_, .blocked):
                CGColor(
                    red: max(-0.6 + 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2, alpha: 1.0)
            default:
                CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            }
        default: CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }

    cgContext.setFillColor(greenLight)
    cgContext.fillEllipse(
        in: viewContext.toViewRect(Rect.square(around: c2, length: 2.0 * lightRadius)))
    cgContext.setFillColor(redLight)
    cgContext.fillEllipse(
        in: viewContext.toViewRect(Rect.square(around: c1, length: 2.0 * lightRadius)))
}

private func drawWithHighDetail(
    _ signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    drawLight(signal, cgContext, viewContext, dirtyRect)
    drawBasket(signal, cgContext, viewContext, dirtyRect)
    drawBoard(signal, cgContext, viewContext, dirtyRect)
}

private func drawBasket(
    _ signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    let forward = signal.orientation.asAngle
    let left = signal.orientation.asAngle + 90.0.deg
    let right = signal.orientation.asAngle - 90.0.deg

    let p1 = signal.point + forward ** 0.1.m + left ** 0.5.m
    let p2 = signal.point + forward ** 0.9.m + left ** 0.5.m
    let p3 = signal.point + forward ** 0.9.m + right ** 0.5.m
    let p4 = signal.point + forward ** 0.1.m + right ** 0.5.m

    let p5 = signal.point + forward ** 0.1.m + left ** 0.4.m
    let p6 = signal.point + forward ** 0.8.m + left ** 0.4.m
    let p7 = signal.point + forward ** 0.8.m + right ** 0.4.m
    let p8 = signal.point + forward ** 0.1.m + right ** 0.4.m

    let p9 = signal.point + forward ** 0.7.m + left ** 0.5.m
    let p10 = signal.point + forward ** 0.7.m + right ** 0.4.m
    let p11 = signal.point + forward ** 0.7.m + left ** 0.4.m
    let p12 = signal.point + forward ** 0.7.m + right ** 0.5.m

    cgContext.setStrokeColor(CGColor(gray: 0.6, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(0.06.m))
    cgContext.move(to: viewContext.toViewPoint(p1))
    cgContext.addLine(to: viewContext.toViewPoint(p2))
    cgContext.addLine(to: viewContext.toViewPoint(p3))
    cgContext.addLine(to: viewContext.toViewPoint(p4))
    cgContext.strokePath()

    cgContext.move(to: viewContext.toViewPoint(p9))
    cgContext.addLine(to: viewContext.toViewPoint(p10))
    cgContext.strokePath()

    cgContext.move(to: viewContext.toViewPoint(p11))
    cgContext.addLine(to: viewContext.toViewPoint(p12))
    cgContext.strokePath()

    cgContext.setFillColor(CGColor(gray: 0.4, alpha: 1.0))
    cgContext.move(to: viewContext.toViewPoint(p5))
    cgContext.addLine(to: viewContext.toViewPoint(p6))
    cgContext.addLine(to: viewContext.toViewPoint(p7))
    cgContext.addLine(to: viewContext.toViewPoint(p8))
    cgContext.fillPath()
}

private func drawBoard(
    _ signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    let forward = signal.orientation.asAngle
    let backward = signal.orientation.asAngle + 180.0.deg
    let left = signal.orientation.asAngle + 90.0.deg
    let right = signal.orientation.asAngle - 90.0.deg

    let p1 = signal.point + left ** 0.65.m + forward ** 0.09.m
    let p2 = signal.point + right ** 0.65.m + forward ** 0.09.m
    let p3 = signal.point + left ** 0.17.m + backward ** 0.05.m
    let p4 = signal.point + backward ** 0.8.m
    let p5 = signal.point + right ** 0.17.m + backward ** 0.05.m

    cgContext.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(0.18.m))
    cgContext.move(to: viewContext.toViewPoint(p1))
    cgContext.addLine(to: viewContext.toViewPoint(p2))
    cgContext.strokePath()

    cgContext.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(0.1.m))
    cgContext.move(to: viewContext.toViewPoint(p3))
    cgContext.addLine(to: viewContext.toViewPoint(p5))
    cgContext.strokePath()

    cgContext.setFillColor(CGColor(gray: 0.05, alpha: 1.0))
    cgContext.move(to: viewContext.toViewPoint(p3))
    cgContext.addQuadCurve(to: viewContext.toViewPoint(p5), control: viewContext.toViewPoint(p4))
    cgContext.closePath()
    cgContext.fillPath()
}

private func drawLight(
    _ signal: Signal, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.saveGState()

    let (lightCenter, lightEdge) =
        switch signal.state {
        case .fixed(.blocked):
            (
                CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5),
                CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
            )
        case .fixed(.go):
            (
                CGColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.5),
                CGColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.0)
            )
        case .changing(let change):
            if change.progress < 0.5 {
                switch change.previous {
                case .blocked:
                    (
                        CGColor(
                            red: 1.0, green: 0.0, blue: 0.0,
                            alpha: max(0.5 - change.progress, 0.0)),
                        CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
                    )
                case .go:
                    (
                        CGColor(
                            red: 0.0, green: 0.8, blue: 0.0,
                            alpha: max(0.5 - change.progress, 0.0)),
                        CGColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.0)
                    )
                }
            } else {
                switch change.next {
                case .blocked:
                    (
                        CGColor(
                            red: 1.0, green: 0.0, blue: 0.0,
                            alpha: max(-0.5 + change.progress, 0.0)),
                        CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
                    )
                case .go:
                    (
                        CGColor(
                            red: 0.0, green: 0.8, blue: 0.0,
                            alpha: max(-0.5 + change.progress, 0.0)),
                        CGColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 0.0)
                    )
                }
            }
        }

    let forward = signal.orientation.asAngle
    let backward = signal.orientation.asAngle + 180.0.deg
    let left = signal.orientation.asAngle + 90.0.deg
    let right = signal.orientation.asAngle - 90.0.deg
    let p1 = signal.point + backward ** 5.0.m + left ** 1.2.m
    let p2 = signal.point + forward ** 5.0.m
    let p3 = signal.point + backward ** 5.0.m + right ** 1.2.m
    let p4 = signal.point + backward ** 5.0.m

    cgContext.move(to: viewContext.toViewPoint(p1))
    cgContext.addQuadCurve(to: viewContext.toViewPoint(p3), control: viewContext.toViewPoint(p2))
    cgContext.addLine(to: viewContext.toViewPoint(p3))
    cgContext.closePath()
    cgContext.clip()
    cgContext.drawLinearGradient(
        CGGradient(
            colorsSpace: nil,
            colors: [lightCenter, lightEdge] as CFArray,
            locations: nil)!,
        start: viewContext.toViewPoint(signal.point),
        end: viewContext.toViewPoint(p4),
        options: CGGradientDrawingOptions())

    cgContext.restoreGState()
}
