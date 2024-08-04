//
//  Drawing.swift
//  Train Dispatcher Tracks
//
//  Created by Arne Philipeit on 3/9/24.
//

import Base
import CoreGraphics
import Foundation

public func draw(
    tracks: some Sequence<Track>, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.saveGState()
    if viewContext.mapScale < 5.0 {
        for track in tracks {
            drawWithLowDetail(track, cgContext, viewContext, dirtyRect)
        }
    } else {
        let drawFuncs =
            if viewContext.mapScale < 8.0 {
                [drawBedFoundations, drawBed, drawRails]
            } else {
                [drawBedFoundations, drawBed, drawSleepers, drawRails]
            }
        for drawFunc in drawFuncs {
            for track in tracks {
                drawFunc(track, cgContext, viewContext, dirtyRect)
            }
        }
    }
    cgContext.restoreGState()
}

private func drawWithLowDetail(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    switch viewContext.style {
    case .light:
        cgContext.setStrokeColor(CGColor.init(gray: 0.35, alpha: 1.0))
    case .dark:
        cgContext.setStrokeColor(CGColor.init(gray: 0.7, alpha: 1.0))
    }
    cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
    stroke(path: track.path, cgContext, viewContext, trackBedWidth, dirtyRect)
}

private func drawBedFoundations(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.7, blue: 0.65, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(trackBedWidth))
    stroke(path: track.path, cgContext, viewContext, trackBedWidth, dirtyRect)
}

private func drawBed(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.setStrokeColor(CGColor.init(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperLength + 0.6.m))
    stroke(path: track.path, cgContext, viewContext, sleeperLength + 0.6.m, dirtyRect)
}

private func drawSleepers(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.setStrokeColor(CGColor(red: 0.6, green: 0.4, blue: 0.0, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(sleeperWidth))
    let startS = sleeperWidth
    let endS = track.path.length - sleeperWidth
    let deltaS = endS - startS
    let stepS = deltaS / floor(deltaS / minSleeperOffset)
    for segment in track.path.segments(
        inRect: dirtyRect.insetBy(
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
            if !Rect.intersect(dirtyRect, Rect.square(around: center, length: sleeperLength)) {
                continue
            }
            let orientation = track.path.orientation(at: Distance(s))!
            let left = center + 0.5 * sleeperLength ** (orientation + 90.0.deg)
            let right = center + 0.5 * sleeperLength ** (orientation - 90.0.deg)
            cgContext.move(to: viewContext.toViewPoint(left))
            cgContext.addLine(to: viewContext.toViewPoint(right))
            cgContext.drawPath(using: .stroke)
        }
    }
}

private func drawRails(
    _ track: Track, _ cgContext: CGContext, _ viewContext: ViewContext,
    _ dirtyRect: Rect
) {
    cgContext.setStrokeColor(CGColor.init(gray: 0.5, alpha: 1.0))
    cgContext.setLineWidth(viewContext.toViewDistance(railBottomWidth))
    for rail in [track.leftRail, track.rightRail] {
        stroke(path: rail, cgContext, viewContext, railBottomWidth, dirtyRect)
    }
}
