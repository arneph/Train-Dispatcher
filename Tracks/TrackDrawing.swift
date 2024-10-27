//
//  Drawing.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import CoreGraphics
import Foundation

public func draw(trackMap map: TrackMap, ctx: DrawContext) {
    ctx.saveGState()
    if ctx.mapScale < 5.0 {
        for track in map.tracks {
            drawWithLowDetail(track, ctx)
        }
        for connection in map.connections {
            drawWithLowDetail(connection, .a, ctx)
            drawWithLowDetail(connection, .b, ctx)
        }
    } else {
        let drawFuncs =
            if ctx.mapScale < 8.0 {
                [drawBedFoundations, drawBed, drawRails]
            } else {
                [drawBedFoundations, drawBed, drawSleepers, drawRails]
            }
        for drawFunc in drawFuncs {
            for track in map.tracks {
                drawFunc(track, ctx)
            }
        }
    }
    ctx.restoreGState()
}

private func drawWithLowDetail(
    _ track: Track, _ ctx: DrawContext
) {
    switch ctx.style {
    case .light:
        ctx.setStrokeColor(CGColor.init(gray: 0.35, alpha: 1.0))
    case .dark:
        ctx.setStrokeColor(CGColor.init(gray: 0.7, alpha: 1.0))
    }
    ctx.setLineWidth(trackBedWidth)
    ctx.stroke(path: track.path, trackBedWidth)
}

private func drawWithLowDetail(
    _ connection: TrackConnection, _ direction: TrackConnection.Direction, _ ctx: DrawContext
) {
    if !connection.hasSwitch(inDirection: direction) {
        return
    }
    switch connection.state(inDirection: direction) {
    case .fixed(let track):
        ctx.setStrokeColor(CGColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0))
        ctx.stroke(path: connection.switchPath(for: track), trackBedWidth)
    case .changing(let change):
        if change.progress < 0.5 {
            ctx.setStrokeColor(
                CGColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0 - 2.0 * change.progress))
            ctx.stroke(path: connection.switchPath(for: change.previous), trackBedWidth)
        } else {
            ctx.setStrokeColor(
                CGColor.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 2.0 * change.progress - 1.0))
            ctx.stroke(path: connection.switchPath(for: change.next), trackBedWidth)
        }
    case .none:
        return
    }
}

private func drawBedFoundations(
    _ track: Track, _ ctx: DrawContext
) {
    ctx.setStrokeColor(CGColor.init(red: 0.7, green: 0.7, blue: 0.65, alpha: 1.0))
    ctx.setLineWidth(trackBedWidth)
    ctx.stroke(path: track.path, trackBedWidth)
}

private func drawBed(
    _ track: Track, _ ctx: DrawContext
) {
    ctx.setStrokeColor(CGColor.init(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0))
    ctx.setLineWidth(sleeperLength + 0.6.m)
    ctx.stroke(path: track.path, sleeperLength + 0.6.m)
}

private func drawSleepers(
    _ track: Track, _ ctx: DrawContext
) {
    ctx.setStrokeColor(CGColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0))
    ctx.setLineWidth(sleeperWidth)
    let startS = sleeperWidth
    let endS = track.path.length - sleeperWidth
    let deltaS = endS - startS
    let stepS = deltaS / floor(deltaS / minSleeperOffset)
    for segment in track.path.segments(
        inRect: ctx.dirtyRect.insetBy(
            dx: -sleeperLength,
            dy: -sleeperLength))
    {
        let localStartS = max(
            startS, ((segment.lowerBound - startS) / stepS).rounded(.down) * stepS)
        let localEndS = min(endS, ((segment.upperBound - startS) / stepS).rounded(.up) * stepS)
        for s in stride(
            from: localStartS.withoutUnit,
            through: localEndS.withoutUnit,
            by: stepS.withoutUnit)
        {
            let center = track.path.point(at: Distance(s))!
            if !Rect.intersect(ctx.dirtyRect, Rect.square(around: center, length: sleeperLength)) {
                continue
            }
            let orientation = track.path.orientation(at: Distance(s))!
            let left = center + 0.5 * sleeperLength ** (orientation + 90.0.deg)
            let right = center + 0.5 * sleeperLength ** (orientation - 90.0.deg)
            ctx.move(to: left)
            ctx.addLine(to: right)
            ctx.drawPath(using: .stroke)
        }
    }
}

private func drawRails(
    _ track: Track, _ ctx: DrawContext
) {
    ctx.setStrokeColor(CGColor.init(gray: 0.5, alpha: 1.0))
    ctx.setLineWidth(railBottomWidth)
    for rail in [track.leftRail, track.rightRail] {
        ctx.stroke(path: rail, railBottomWidth)
    }
}
