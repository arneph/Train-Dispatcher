//
//  SignalDrawing.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/12/24.
//

import Base
import CoreGraphics
import Foundation

public func draw(signal: Signal, ctx: DrawContext) {
    ctx.saveGState()
    if ctx.mapScale < 5.0 {
        drawWithLowDetail(signal, ctx)
    } else {
        drawWithHighDetail(signal, ctx)
    }
    ctx.restoreGState()
}

private func drawWithLowDetail(_ signal: Signal, _ ctx: DrawContext) {
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

    ctx.setLineWidth(supportWidth)
    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))

    ctx.move(to: c1)
    ctx.addLine(to: p5)
    ctx.strokePath()

    ctx.move(to: p6)
    ctx.addLine(to: p7)
    ctx.strokePath()

    ctx.setLineWidth(0.02.m)
    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.setFillColor(CGColor(gray: 0.0, alpha: 1.0))

    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.addArc(
        center: c1,
        radius: boardRadius,
        startAngle: left,
        endAngle: right,
        clockwise: false)
    ctx.addLine(to: p3)
    ctx.addLine(to: p4)
    ctx.addArc(
        center: c2,
        radius: boardRadius,
        startAngle: right,
        endAngle: left,
        clockwise: false)
    ctx.closePath()
    ctx.fillPath()
    ctx.strokePath()

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

    ctx.setFillColor(greenLight)
    ctx.fillEllipse(in: Rect.square(around: c2, length: 2.0 * lightRadius))
    ctx.setFillColor(redLight)
    ctx.fillEllipse(in: Rect.square(around: c1, length: 2.0 * lightRadius))
}

private func drawWithHighDetail(_ signal: Signal, _ ctx: DrawContext) {
    drawLight(signal, ctx)
    drawBasket(signal, ctx)
    drawBoard(signal, ctx)
}

private func drawBasket(_ signal: Signal, _ ctx: DrawContext) {
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

    ctx.setStrokeColor(CGColor(gray: 0.6, alpha: 1.0))
    ctx.setLineWidth(0.06.m)
    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.addLine(to: p3)
    ctx.addLine(to: p4)
    ctx.strokePath()

    ctx.move(to: p9)
    ctx.addLine(to: p10)
    ctx.strokePath()

    ctx.move(to: p11)
    ctx.addLine(to: p12)
    ctx.strokePath()

    ctx.setFillColor(CGColor(gray: 0.4, alpha: 1.0))
    ctx.move(to: p5)
    ctx.addLine(to: p6)
    ctx.addLine(to: p7)
    ctx.addLine(to: p8)
    ctx.fillPath()
}

private func drawBoard(_ signal: Signal, _ ctx: DrawContext) {
    let forward = signal.orientation.asAngle
    let backward = signal.orientation.asAngle + 180.0.deg
    let left = signal.orientation.asAngle + 90.0.deg
    let right = signal.orientation.asAngle - 90.0.deg

    let p1 = signal.point + left ** 0.65.m + forward ** 0.09.m
    let p2 = signal.point + right ** 0.65.m + forward ** 0.09.m
    let p3 = signal.point + left ** 0.17.m + backward ** 0.05.m
    let p4 = signal.point + backward ** 0.8.m
    let p5 = signal.point + right ** 0.17.m + backward ** 0.05.m

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.setLineWidth(0.18.m)
    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.strokePath()

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.setLineWidth(0.1.m)
    ctx.move(to: p3)
    ctx.addLine(to: p5)
    ctx.strokePath()

    ctx.setFillColor(CGColor(gray: 0.05, alpha: 1.0))
    ctx.move(to: p3)
    ctx.addQuadCurve(to: p5, control: p4)
    ctx.closePath()
    ctx.fillPath()
}

private func drawLight(_ signal: Signal, _ ctx: DrawContext) {
    ctx.saveGState()

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

    ctx.move(to: p1)
    ctx.addQuadCurve(to: p3, control: p2)
    ctx.addLine(to: p3)
    ctx.closePath()
    ctx.clip()
    ctx.drawLinearGradient(
        CGGradient(
            colorsSpace: nil,
            colors: [lightCenter, lightEdge] as CFArray,
            locations: nil)!,
        start: signal.point,
        end: p4,
        options: CGGradientDrawingOptions())

    ctx.restoreGState()
}
