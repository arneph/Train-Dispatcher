//
//  SignalDrawing.swift
//  Tracks
//
//  Created by Arne Philipeit on 10/12/24.
//

import Base
import CoreGraphics
import Foundation

private enum SignalDrawState {
    case real, proposed

    fileprivate var alpha: CGFloat {
        switch self {
        case .real: 1.0
        case .proposed: 0.5
        }
    }
}

private struct SignalDrawInfo {
    let position: PointAndOrientation
    let state: Signal.State
    let drawState: SignalDrawState

    var point: Point { position.point }
    var orientation: Angle { position.orientation.asAngle }

    var forward: Angle { orientation }
    var backward: Angle { orientation + 180.deg }
    var left: Angle { orientation + 90.0.deg }
    var right: Angle { orientation - 90.0.deg }
}

public func draw(signal: Signal, ctx: DrawContext) {
    let info = SignalDrawInfo(position: signal.position, state: signal.state, drawState: .real)
    ctx.saveGState()
    switch signal.kind {
    case .section:
        if ctx.mapScale < 5.0 {
            drawSectionSignalWithLowDetail(info, ctx)
        } else {
            drawSectionSignalWithHighDetail(info, ctx)
        }
    case .main:
        if ctx.mapScale < 5.0 {
            drawMainSignalWithLowDetail(info, ctx)
        } else {
            drawMainSignalWithHighDetail(info, ctx)
        }
    }
    ctx.restoreGState()
}

public func drawProposedSectionSignal(at position: PointAndOrientation, ctx: DrawContext) {
    let info = SignalDrawInfo(position: position, state: .fixed(.blocked), drawState: .proposed)
    ctx.saveGState()
    if ctx.mapScale < 5.0 {
        drawSectionSignalWithLowDetail(info, ctx)
    } else {
        drawSectionSignalWithHighDetail(info, ctx)
    }
    ctx.restoreGState()
}

public func drawProposedMainSignal(at position: PointAndOrientation, ctx: DrawContext) {
    let info = SignalDrawInfo(position: position, state: .fixed(.blocked), drawState: .proposed)
    ctx.saveGState()
    if ctx.mapScale < 5.0 {
        drawMainSignalWithLowDetail(info, ctx)
    } else {
        drawMainSignalWithHighDetail(info, ctx)
    }
    ctx.restoreGState()
}

private func drawSectionSignalWithLowDetail(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    let lightRadius = 0.5.m
    let lightRim = 0.15.m
    let boardRadius = lightRadius + lightRim

    let p1 = info.point + info.left ** boardRadius
    let p2 = info.point + info.right ** boardRadius
    let p3 = info.point + info.right ** boardRadius + info.backward ** boardRadius
    let p4 = info.point + info.left ** boardRadius + info.backward ** boardRadius

    ctx.setFillColor(CGColor(gray: 0.0, alpha: info.drawState.alpha))
    ctx.move(to: p1)
    ctx.addArc(
        center: info.point,
        radius: boardRadius,
        startAngle: info.left,
        endAngle: info.right,
        clockwise: true)
    ctx.addLine(to: p2)
    ctx.addLine(to: p3)
    ctx.addLine(to: p4)
    ctx.closePath()
    ctx.fillPath()

    let light =
        switch info.state {
        case .fixed(.blocked): CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
        case .fixed(.go): CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: info.drawState.alpha)
        case .changing(let change):
            switch (change.previous, change.next) {
            case (.blocked, .blocked):
                CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
            case (.go, .go):
                CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: info.drawState.alpha)
            case (.blocked, .go):
                if change.progress < 0.5 {
                    CGColor(
                        red: max(1.0 - 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2,
                        alpha: info.drawState.alpha)
                } else {
                    CGColor(
                        red: max(-0.5 + 1.4 * change.progress, 0.2),
                        green: max(-0.5 + 1.4 * change.progress, 0.2),
                        blue: max(-0.5 + 1.4 * change.progress, 0.2),
                        alpha: info.drawState.alpha)
                }
            case (.go, .blocked):
                if change.progress < 0.5 {
                    CGColor(
                        red: max(0.9 - 1.4 * change.progress, 0.2),
                        green: max(0.9 - 1.4 * change.progress, 0.2),
                        blue: max(0.9 - 1.4 * change.progress, 0.2),
                        alpha: info.drawState.alpha)
                } else {
                    CGColor(
                        red: max(-0.6 + 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2,
                        alpha: info.drawState.alpha)
                }
            }
        }
    ctx.setFillColor(light)
    ctx.fillCircle(at: info.point, radius: lightRadius)
}

private func drawMainSignalWithLowDetail(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    let possibleStates = 2
    let lightRadius = 0.5.m
    let lightRim = 0.15.m
    let boardRadius = lightRadius + lightRim
    let boardHeight = lightRim + possibleStates * (2 * lightRadius + lightRim)
    let supportHeight = 0.6.m
    let supportWidth = 0.3.m

    let p1 =
        info.point + info.forward ** (0.5 * boardHeight - boardRadius) + info.left ** boardRadius
    let p2 =
        info.point + info.backward ** (0.5 * boardHeight - boardRadius) + info.left ** boardRadius
    let p3 =
        info.point + info.backward ** (0.5 * boardHeight - boardRadius) + info.right ** boardRadius
    let p4 =
        info.point + info.forward ** (0.5 * boardHeight - boardRadius) + info.right ** boardRadius
    let p5 = info.point + info.backward ** (0.5 * boardHeight + supportHeight)
    let p6 =
        info.point + info.backward ** (0.5 * boardHeight + supportHeight) + info.left ** boardRadius
    let p7 =
        info.point + info.backward ** (0.5 * boardHeight + supportHeight) + info.right
        ** boardRadius
    let c1 = info.point + info.backward ** (0.5 * boardHeight - boardRadius)
    let c2 = info.point + info.forward ** (0.5 * boardHeight - boardRadius)

    ctx.setLineWidth(supportWidth)
    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))

    ctx.move(to: c1)
    ctx.addLine(to: p5)
    ctx.strokePath()

    ctx.move(to: p6)
    ctx.addLine(to: p7)
    ctx.strokePath()

    ctx.setLineWidth(0.02.m)
    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.setFillColor(CGColor(gray: 0.0, alpha: info.drawState.alpha))

    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.addArc(
        center: c1,
        radius: boardRadius,
        startAngle: info.left,
        endAngle: info.right,
        clockwise: false)
    ctx.addLine(to: p3)
    ctx.addLine(to: p4)
    ctx.addArc(
        center: c2,
        radius: boardRadius,
        startAngle: info.right,
        endAngle: info.left,
        clockwise: false)
    ctx.closePath()
    ctx.fillPath()
    ctx.strokePath()

    let greenLight =
        switch info.state {
        case .fixed(.go): CGColor(red: 0.2, green: 1.0, blue: 0.2, alpha: info.drawState.alpha)
        case .changing(let change):
            switch (change.previous, change.next) {
            case (.go, .go): CGColor(red: 0.2, green: 1.0, blue: 0.2, alpha: info.drawState.alpha)
            case (.go, _):
                CGColor(
                    red: 0.2, green: max(1.0 - 1.6 * change.progress, 0.2), blue: 0.2,
                    alpha: info.drawState.alpha)
            case (_, .go):
                CGColor(
                    red: 0.2, green: max(-0.6 + 1.6 * change.progress, 0.2), blue: 0.2,
                    alpha: info.drawState.alpha)
            default:
                CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
            }
        default: CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
        }
    let redLight =
        switch info.state {
        case .fixed(.blocked): CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
        case .changing(let change):
            switch (change.previous, change.next) {
            case (.blocked, .blocked):
                CGColor(red: 1.0, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
            case (.blocked, _):
                CGColor(
                    red: max(1.0 - 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2,
                    alpha: info.drawState.alpha)
            case (_, .blocked):
                CGColor(
                    red: max(-0.6 + 1.6 * change.progress, 0.2), green: 0.2, blue: 0.2,
                    alpha: info.drawState.alpha)
            default:
                CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
            }
        default: CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: info.drawState.alpha)
        }

    ctx.setFillColor(greenLight)
    ctx.fillCircle(at: c2, radius: lightRadius)
    ctx.setFillColor(redLight)
    ctx.fillCircle(at: c1, radius: lightRadius)
}

private func drawSectionSignalWithHighDetail(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    switch info.drawState {
    case .real:
        drawSectionSignalLight(info, ctx)
    case .proposed:
        break
    }
    drawSectionSignalBody(info, ctx)
}

private func drawSectionSignalBody(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    let p1 = info.point + info.left ** 0.25.m + info.forward ** 0.15.m
    let p2 = info.point + info.right ** 0.25.m + info.forward ** 0.15.m
    let p3 = info.point + info.left ** 0.12.m + info.backward ** 0.05.m
    let p4 = info.point + info.backward ** 0.2.m
    let p5 = info.point + info.right ** 0.12.m + info.backward ** 0.05.m

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.setLineWidth(0.30.m)
    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.strokePath()

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.setLineWidth(0.1.m)
    ctx.move(to: p3)
    ctx.addLine(to: p5)
    ctx.strokePath()

    ctx.setFillColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.move(to: p3)
    ctx.addQuadCurve(to: p5, control: p4)
    ctx.closePath()
    ctx.fillPath()
}

private func drawSectionSignalLight(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    ctx.saveGState()

    let (lightCenter, lightEdge) =
        switch info.state {
        case .fixed(.blocked):
            (
                CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5),
                CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
            )
        case .fixed(.go):
            (
                CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.5),
                CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.0)
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
                            red: 0.9, green: 0.9, blue: 0.9,
                            alpha: max(0.5 - change.progress, 0.0)),
                        CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.0)
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
                            red: 0.9, green: 0.9, blue: 0.9,
                            alpha: max(-0.5 + change.progress, 0.0)),
                        CGColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 0.0)
                    )
                }
            }
        }

    let p1 = info.point + info.backward ** 2.0.m + info.left ** 0.6.m
    let p2 = info.point + info.forward ** 2.0.m
    let p3 = info.point + info.backward ** 2.0.m + info.right ** 0.6.m
    let p4 = info.point + info.backward ** 2.0.m

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
        start: info.point,
        end: p4,
        options: CGGradientDrawingOptions())

    ctx.restoreGState()
}

private func drawMainSignalWithHighDetail(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    switch info.drawState {
    case .real:
        drawMainSignalLight(info, ctx)
    case .proposed:
        break
    }
    drawBasket(info, ctx)
    drawBoard(info, ctx)
}

private func drawBasket(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    let p1 = info.point + info.forward ** 0.1.m + info.left ** 0.5.m
    let p2 = info.point + info.forward ** 0.9.m + info.left ** 0.5.m
    let p3 = info.point + info.forward ** 0.9.m + info.right ** 0.5.m
    let p4 = info.point + info.forward ** 0.1.m + info.right ** 0.5.m

    let p5 = info.point + info.forward ** 0.1.m + info.left ** 0.4.m
    let p6 = info.point + info.forward ** 0.8.m + info.left ** 0.4.m
    let p7 = info.point + info.forward ** 0.8.m + info.right ** 0.4.m
    let p8 = info.point + info.forward ** 0.1.m + info.right ** 0.4.m

    let p9 = info.point + info.forward ** 0.7.m + info.left ** 0.5.m
    let p10 = info.point + info.forward ** 0.7.m + info.right ** 0.4.m
    let p11 = info.point + info.forward ** 0.7.m + info.left ** 0.4.m
    let p12 = info.point + info.forward ** 0.7.m + info.right ** 0.5.m

    ctx.setStrokeColor(CGColor(gray: 0.6, alpha: info.drawState.alpha))
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

    ctx.setFillColor(CGColor(gray: 0.4, alpha: info.drawState.alpha))
    ctx.move(to: p5)
    ctx.addLine(to: p6)
    ctx.addLine(to: p7)
    ctx.addLine(to: p8)
    ctx.fillPath()
}

private func drawBoard(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    let p1 = info.point + info.left ** 0.65.m + info.forward ** 0.09.m
    let p2 = info.point + info.right ** 0.65.m + info.forward ** 0.09.m
    let p3 = info.point + info.left ** 0.17.m + info.backward ** 0.05.m
    let p4 = info.point + info.backward ** 0.8.m
    let p5 = info.point + info.right ** 0.17.m + info.backward ** 0.05.m

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.setLineWidth(0.18.m)
    ctx.move(to: p1)
    ctx.addLine(to: p2)
    ctx.strokePath()

    ctx.setStrokeColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.setLineWidth(0.1.m)
    ctx.move(to: p3)
    ctx.addLine(to: p5)
    ctx.strokePath()

    ctx.setFillColor(CGColor(gray: 0.05, alpha: info.drawState.alpha))
    ctx.move(to: p3)
    ctx.addQuadCurve(to: p5, control: p4)
    ctx.closePath()
    ctx.fillPath()
}

private func drawMainSignalLight(_ info: SignalDrawInfo, _ ctx: DrawContext) {
    ctx.saveGState()

    let (lightCenter, lightEdge) =
        switch info.state {
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

    let p1 = info.point + info.backward ** 5.0.m + info.left ** 1.2.m
    let p2 = info.point + info.forward ** 5.0.m
    let p3 = info.point + info.backward ** 5.0.m + info.right ** 1.2.m
    let p4 = info.point + info.backward ** 5.0.m

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
        start: info.point,
        end: p4,
        options: CGGradientDrawingOptions())

    ctx.restoreGState()
}
